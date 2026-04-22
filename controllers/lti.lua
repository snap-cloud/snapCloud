-- LTI 1.3 Tool controller
-- =======================
--
-- This controller implements the IMS LTI 1.3 specification from the tool side.
-- Three public endpoints are exposed to LMS platforms:
--
--   * OIDC Initiation (/lti/login)  - receives a third-party-initiated login
--     request from the platform and redirects the user-agent to the platform
--     with the state + nonce we want echoed back.
--   * Launch (/lti/launch)          - receives the id_token from the platform,
--     verifies it against the platform's JWKS, and creates or re-uses a
--     Snap!Cloud user bound to the LTI subject.
--   * JWKS (/lti/jwks)              - exposes the tool's public key(s) as a
--     JSON Web Key Set.
--
-- In addition the controller exposes teacher-facing endpoints used to register
-- an LMS platform as an LTI deployment of the Snap!Cloud tool.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2026 by Bernat Romagosa and Michael Ball
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local db = package.loaded.db
local util = package.loaded.util
local yield_error = package.loaded.yield_error
local capture_errors = package.loaded.capture_errors
local config = package.loaded.config

local Users = package.loaded.Users
local AllUsers = package.loaded.AllUsers
local LtiPlatforms = package.loaded.LtiPlatforms
local LtiUsers = package.loaded.LtiUsers

local jwt = require('lib.jwt')
local cjson = require('cjson')
-- Pull in global helpers we share with other controllers.
require 'passwords'

-- Errors re-used across endpoints.
local err_platform_not_found = {
    msg = 'The LTI platform for this request has not been registered ' ..
          'with the Snap!Cloud. Ask your admin to register the LMS ' ..
          'before attempting to launch.',
    status = 400
}
local err_not_logged_in =
    { msg = 'You are not logged in', status = 401 }
local err_not_teacher =
    { msg = 'Only teacher (or admin) accounts may manage LTI platforms',
      status = 403 }

-- LTI claim URIs ----------------------------------------------------------

local CLAIM = {
    message_type = 'https://purl.imsglobal.org/spec/lti/claim/message_type',
    version = 'https://purl.imsglobal.org/spec/lti/claim/version',
    deployment_id = 'https://purl.imsglobal.org/spec/lti/claim/deployment_id',
    target_link_uri = 'https://purl.imsglobal.org/spec/lti/claim/target_link_uri',
    resource_link = 'https://purl.imsglobal.org/spec/lti/claim/resource_link',
    roles = 'https://purl.imsglobal.org/spec/lti/claim/roles',
    context = 'https://purl.imsglobal.org/spec/lti/claim/context'
}

-- A role value is considered instructor-like (teacher) if it matches one of
-- these IMS role URIs (or short forms).
local INSTRUCTOR_ROLE_PATTERNS = {
    'Instructor',
    'ContentDeveloper',
    'Faculty',
    'Administrator',
    'Staff',
    'Mentor'
}

local function is_teacher_role(roles)
    if type(roles) ~= 'table' then return false end
    for _, role in ipairs(roles) do
        for _, pat in ipairs(INSTRUCTOR_ROLE_PATTERNS) do
            if string.find(role, pat, 1, true) then
                return true
            end
        end
    end
    return false
end

local function is_learner_role(roles)
    if type(roles) ~= 'table' then return false end
    for _, role in ipairs(roles) do
        if string.find(role, 'Learner', 1, true) or
                string.find(role, 'Student', 1, true) then
            return true
        end
    end
    return false
end

-- Tool key management ------------------------------------------------------

local pkey = require('openssl.pkey')
local tool_key_cache = nil

local function tool_key()
    if tool_key_cache then return tool_key_cache end
    local pem = os.getenv('LTI_TOOL_PRIVATE_KEY')
    if pem and pem ~= '' then
        local ok, key = pcall(pkey.new, pem)
        if ok and key then
            tool_key_cache = {
                key = key,
                kid = os.getenv('LTI_TOOL_KID') or 'snap-cloud-lti-1',
                ephemeral = false
            }
            return tool_key_cache
        end
        ngx.log(ngx.ERR,
            'LTI_TOOL_PRIVATE_KEY is set but could not be parsed: ' ..
            tostring(key))
    end
    -- Fall back to a per-process RSA key. This is good enough to boot the
    -- tool up and serve a valid JWKS, but service-side operations that need
    -- the platform to verify the tool's signature will require a persistent
    -- key in production.
    ngx.log(ngx.WARN,
        'LTI tool is using an ephemeral RSA key. ' ..
        'Set LTI_TOOL_PRIVATE_KEY in the environment for production use.')
    tool_key_cache = {
        key = pkey.new({ type = 'RSA', bits = 2048 }),
        kid = os.getenv('LTI_TOOL_KID') or 'snap-cloud-lti-ephemeral',
        ephemeral = true
    }
    return tool_key_cache
end

-- JWKS fetching ------------------------------------------------------------

local jwks_cache_dict = ngx.shared.lti_jwks_cache
local JWKS_CACHE_SECONDS = 15 * 60

local function fetch_jwks(url)
    if not url then return nil, 'jwks url is missing' end
    if jwks_cache_dict then
        local cached = jwks_cache_dict:get(url)
        if cached then
            local ok, parsed = pcall(cjson.decode, cached)
            if ok and parsed then return parsed end
        end
    end
    local http = require('resty.http')
    local client, cerr = http.new()
    if not client then return nil, 'could not create http client: ' .. tostring(cerr) end
    client:set_timeout(10000)
    local res, rerr = client:request_uri(url, {
        method = 'GET',
        headers = { ['Accept'] = 'application/json' },
        ssl_verify = true
    })
    if not res then
        return nil, 'failed to fetch jwks: ' .. tostring(rerr)
    end
    if res.status ~= 200 then
        return nil, 'jwks endpoint returned HTTP ' .. tostring(res.status)
    end
    local ok, parsed = pcall(cjson.decode, res.body)
    if not ok or type(parsed) ~= 'table' or not parsed.keys then
        return nil, 'jwks endpoint returned malformed JSON'
    end
    if jwks_cache_dict then
        jwks_cache_dict:set(url, res.body, JWKS_CACHE_SECONDS)
    end
    return parsed
end

-- Nonce / state storage ---------------------------------------------------
-- We keep the nonce + state pair and the platform_id in shared dict so we can
-- verify them when the platform POSTs back the id_token.

local oidc_state_dict = ngx.shared.lti_oidc_state
local OIDC_STATE_SECONDS = 10 * 60

local function remember_oidc_state(state, record)
    if not oidc_state_dict then return end
    oidc_state_dict:set(state, cjson.encode(record), OIDC_STATE_SECONDS)
end

local function recall_oidc_state(state)
    if not oidc_state_dict or not state then return nil end
    local raw = oidc_state_dict:get(state)
    if not raw then return nil end
    -- State is single-use, clean it up immediately.
    oidc_state_dict:delete(state)
    local ok, parsed = pcall(cjson.decode, raw)
    if not ok then return nil end
    return parsed
end

local function random_hex(bytes)
    local resty_random = package.loaded.resty_random
    local resty_string = package.loaded.resty_string
    local raw = resty_random.bytes(bytes, true)
    while raw == nil do raw = resty_random.bytes(bytes, true) end
    return resty_string.to_hex(raw)
end

-- Username/email provisioning ---------------------------------------------

local function sanitize_username(candidate)
    if not candidate then return nil end
    candidate = tostring(candidate):lower()
    -- Allow letters, digits and a small set of common separators.
    candidate = candidate:gsub('[^%w%-_%.]', '_')
    -- Strip leading/trailing separators and collapse runs of underscores.
    candidate = candidate:gsub('^_+', ''):gsub('_+$', ''):gsub('__+', '_')
    if #candidate < 4 then return nil end
    if #candidate > 60 then candidate = candidate:sub(1, 60) end
    return candidate
end

local function generate_username(claims, platform, lti_sub)
    local candidates = {
        sanitize_username(claims.preferred_username),
        sanitize_username(claims.given_name and claims.family_name
            and (claims.given_name .. '.' .. claims.family_name)),
        sanitize_username(claims.name),
        sanitize_username(claims.email and claims.email:match('^([^@]+)')),
        sanitize_username('lti_' .. platform.id .. '_' .. lti_sub)
    }
    for _, base in ipairs(candidates) do
        if base then
            local candidate = base
            local i = 1
            while true do
                local existing = AllUsers:find({ username = candidate })
                if not existing then return candidate end
                i = i + 1
                candidate = base .. '_' .. i
                if i > 50 then break end
            end
        end
    end
    -- Last-resort: fully synthetic unique username.
    return 'lti_' .. platform.id .. '_' .. random_hex(6)
end

local function generate_email(claims, platform, lti_sub)
    if claims.email and claims.email:find('@') then
        return claims.email
    end
    local host = (config.hostname or 'snap.berkeley.edu')
    return 'lti+' .. platform.id .. '+' .. lti_sub:gsub('[^%w%-_%.]', '_')
        .. '@' .. host
end

-- Find-or-create the Snap!Cloud user tied to this LTI subject.
local function find_or_provision_user(claims, platform)
    local lti_sub = claims.sub
    if not lti_sub or lti_sub == '' then
        return nil, 'id_token is missing the required sub claim'
    end

    local link = LtiUsers:find({
        platform_id = platform.id,
        lti_sub = lti_sub
    })
    if link then
        local user = Users:find({ id = link.user_id })
        if user then
            link:update({
                last_launched_at = db.format_date(),
                updated_at = db.format_date()
            })
            return user
        end
    end

    -- Decide the user's role and teacher flag.
    local roles = claims[CLAIM.roles]
    local role = 'standard'
    local is_teacher = false
    if is_teacher_role(roles) then
        is_teacher = true
        role = 'standard'
    elseif is_learner_role(roles) or platform.default_student_role == 'student' then
        role = 'student'
    end

    local username = generate_username(claims, platform, lti_sub)
    local email = generate_email(claims, platform, lti_sub)

    -- Students historically don't need email verification; non-students do.
    local verified = (role == 'student')

    -- A random salt + empty password are fine here because the LTI flow is
    -- the only way this account is meant to be accessed. The user may still
    -- set a normal password via the password-reset flow later if they want
    -- to log in without their LMS.
    local user = Users:create({
        created = db.format_date(),
        username = username,
        salt = secure_salt(),
        password = '',
        email = email,
        verified = verified,
        role = role,
        is_teacher = is_teacher,
        creator_id = platform.creator_id
    })
    if not user then
        return nil,
            'Could not create a Snap!Cloud user for the LTI launch'
    end
    LtiUsers:create({
        platform_id = platform.id,
        lti_sub = lti_sub,
        user_id = user.id,
        last_launched_at = db.format_date()
    })
    return user
end

-- Controller ---------------------------------------------------------------

LtiController = {}

-- GET/POST /lti/login — OIDC third-party-initiated login initiation.
LtiController.login_initiation = capture_errors(function (self)
    local params = self.params
    -- Support both GET and POST bodies.
    local iss = params.iss
    local login_hint = params.login_hint
    local target_link_uri = params.target_link_uri
    local client_id = params.client_id
    local lti_deployment_id = params.lti_deployment_id
    local lti_message_hint = params.lti_message_hint

    if not iss or not login_hint or not target_link_uri then
        return errorResponse(self,
            'Missing iss, login_hint or target_link_uri ' ..
            'for OIDC login initiation.',
            400)
    end

    -- A platform can be identified solely by iss when it has a single
    -- deployment registered; when a client_id is included we use it to
    -- disambiguate.
    local platform
    if client_id then
        platform = LtiPlatforms:find({
            issuer = iss,
            client_id = tostring(client_id)
        })
    else
        local candidates = LtiPlatforms:select(
            'WHERE issuer = ?', iss, { limit = 2 }
        )
        if candidates and #candidates == 1 then
            platform = candidates[1]
        end
    end
    if not platform then
        return errorResponse(self,
            err_platform_not_found.msg,
            err_platform_not_found.status)
    end

    if platform.deployment_id and lti_deployment_id
            and platform.deployment_id ~= lti_deployment_id then
        return errorResponse(self,
            'The LTI deployment_id for this launch does not match the ' ..
            'one registered with the Snap!Cloud.',
            400)
    end

    local state = random_hex(24)
    local nonce = random_hex(24)
    remember_oidc_state(state, {
        platform_id = platform.id,
        nonce = nonce,
        target_link_uri = target_link_uri,
        lti_deployment_id = lti_deployment_id
    })

    -- Build the authorization URL for the platform.
    local redirect_uri = self:build_url('/lti/launch')
    local query = util.encode_query_string({
        scope = 'openid',
        response_type = 'id_token',
        client_id = platform.client_id,
        redirect_uri = redirect_uri,
        login_hint = login_hint,
        state = state,
        response_mode = 'form_post',
        nonce = nonce,
        prompt = 'none',
        lti_message_hint = lti_message_hint or ''
    })
    local sep = platform.auth_login_url:find('?', 1, true) and '&' or '?'
    return { redirect_to = platform.auth_login_url .. sep .. query }
end)

-- POST /lti/launch — receives id_token from the platform.
LtiController.launch = capture_errors(function (self)
    local id_token = self.params.id_token
    local state = self.params.state
    if not id_token or not state then
        return errorResponse(self,
            'Missing id_token or state in LTI launch callback.',
            400)
    end
    local state_record = recall_oidc_state(state)
    if not state_record then
        return errorResponse(self,
            'The LTI launch state could not be validated. ' ..
            'This often happens if the launch took more than ten minutes ' ..
            'or the state was reused. Please relaunch from your LMS.',
            400)
    end
    local platform = LtiPlatforms:find({ id = state_record.platform_id })
    if not platform then
        return errorResponse(self,
            err_platform_not_found.msg,
            err_platform_not_found.status)
    end

    local jwks, jwks_err = fetch_jwks(platform.key_set_url)
    if not jwks then
        return errorResponse(self,
            'Could not retrieve the LMS key set: ' .. tostring(jwks_err),
            502)
    end

    local claims, verr = jwt.verify(id_token, {
        jwks = jwks,
        iss = platform.issuer,
        aud = platform.audience or platform.client_id,
        nonce = state_record.nonce
    })
    if not claims then
        return errorResponse(self,
            'The id_token could not be verified: ' .. tostring(verr),
            401)
    end

    -- Minimum LTI 1.3 claim validation.
    if claims[CLAIM.version] and claims[CLAIM.version] ~= '1.3.0' then
        return errorResponse(self,
            'Only LTI 1.3.0 is supported (got ' ..
            tostring(claims[CLAIM.version]) .. ')',
            400)
    end
    if platform.deployment_id and
            claims[CLAIM.deployment_id] ~= platform.deployment_id then
        return errorResponse(self,
            'LTI deployment_id does not match the registered deployment.',
            400)
    end

    local user, perr = find_or_provision_user(claims, platform)
    if not user then
        return errorResponse(self, perr or 'Failed to provision user.', 500)
    end
    user:update({
        last_login_at = db.format_date(),
        session_count = (user.session_count or 0) + 1
    })

    self.session.username = user.username
    self.session.user_id = user.id
    self.session.verified = user.verified
    self.session.role = user.role
    self.session.persist_session = 'false'

    -- Prefer the platform-provided target_link_uri when we can verify it
    -- points at us; otherwise land the user on their profile.
    local target = claims[CLAIM.target_link_uri] or state_record.target_link_uri
    local base = self:build_url('/')
    if target and target:sub(1, #base) == base then
        return { redirect_to = target }
    end
    return { redirect_to = self:build_url('/') }
end)

-- GET /lti/jwks — publish the tool's public keys.
LtiController.jwks = capture_errors(function (self)
    local info = tool_key()
    local jwk = jwt.pkey_to_jwk(info.key, info.kid)
    return jsonResponse({ keys = { jwk } })
end)

-- Teacher-facing registration helpers --------------------------------------

local function assert_can_manage_platforms(self)
    if not self.current_user then
        yield_error(err_not_logged_in)
    end
    if not (self.current_user.is_teacher or
            self.current_user:has_min_role('admin')) then
        yield_error(err_not_teacher)
    end
end

-- GET /lti/config — teacher-facing page showing the registration values they
-- need to configure their LMS with, plus the list of platforms they have
-- already registered.
LtiController.config_page = capture_errors(function (self)
    assert_can_manage_platforms(self)
    local info = tool_key()
    self.lti = {
        tool_name = config.site_name or 'Snap!Cloud',
        tool_url = self:build_url('/'),
        login_initiation_url = self:build_url('/lti/login'),
        redirect_uri = self:build_url('/lti/launch'),
        target_link_uri = self:build_url('/'),
        jwks_url = self:build_url('/lti/jwks'),
        public_jwk = jwt.pkey_to_jwk(info.key, info.kid),
        kid = info.kid,
        ephemeral_key = info.ephemeral
    }
    self.platforms = LtiPlatforms:select(
        'WHERE creator_id = ? ORDER BY created_at DESC',
        self.current_user.id
    ) or {}
    return { render = 'lti/config' }
end)

-- POST /lti/platforms — register a new LMS deployment.
LtiController.create_platform = capture_errors(function (self)
    assert_can_manage_platforms(self)
    local params = self.params
    local required = { 'name', 'issuer', 'client_id',
                       'auth_login_url', 'key_set_url' }
    for _, key in ipairs(required) do
        if not params[key] or tostring(params[key]) == '' then
            return errorResponse(self,
                'Missing required LTI platform field: ' .. key, 400)
        end
    end
    local existing = LtiPlatforms:find({
        issuer = params.issuer,
        client_id = tostring(params.client_id)
    })
    if existing then
        return errorResponse(self,
            'A platform with this issuer + client_id combination is already ' ..
            'registered.',
            409)
    end
    local platform = LtiPlatforms:create({
        creator_id = self.current_user.id,
        name = params.name,
        issuer = params.issuer,
        client_id = tostring(params.client_id),
        deployment_id = params.deployment_id,
        auth_login_url = params.auth_login_url,
        auth_token_url = params.auth_token_url,
        key_set_url = params.key_set_url,
        audience = params.audience,
        default_student_role = params.default_student_role
    })
    return jsonResponse({
        message = 'LTI platform registered',
        title = 'Platform created',
        platform_id = platform.id,
        redirect = self:build_url('/lti/config')
    })
end)

-- DELETE /lti/platforms/:id — remove a previously registered platform.
LtiController.delete_platform = capture_errors(function (self)
    assert_can_manage_platforms(self)
    local platform =
        LtiPlatforms:find({ id = tonumber(self.params.id) })
    if not platform then
        return errorResponse(self, 'Platform not found.', 404)
    end
    if platform.creator_id ~= self.current_user.id and
            not self.current_user:has_min_role('admin') then
        yield_error({ msg = 'You cannot delete this platform', status = 403 })
    end
    db.delete('lti_users', 'platform_id = ?', platform.id)
    platform:delete()
    return jsonResponse({
        message = 'LTI platform removed',
        redirect = self:build_url('/lti/config')
    })
end)

return LtiController
