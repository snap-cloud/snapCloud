-- OAuth2/OpenID Connect Provider
-- ==============================
--
-- Implements Snap!Cloud as an OAuth2/OIDC identity provider.
-- Supports the Authorization Code flow with OpenID Connect.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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

local app = package.loaded.app
local db = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local respond_to = package.loaded.respond_to
local util = package.loaded.util
local config = package.loaded.config
local cjson = package.loaded.cjson
local encoding = require('lapis.util.encoding')
local resty_string = package.loaded.resty_string

local Users = package.loaded.Users
local OAuthClients = package.loaded.OAuthClients
local OAuthAuthorizationCodes = package.loaded.OAuthAuthorizationCodes
local OAuthRefreshTokens = package.loaded.OAuthRefreshTokens

require('passwords')

-- JWT utilities (HS256)
-- =====================

local function base64url_encode(input)
    local b64 = encoding.encode_base64(input)
    -- Convert standard base64 to base64url
    b64 = b64:gsub('+', '-'):gsub('/', '_'):gsub('=', '')
    return b64
end

local function base64url_decode(input)
    -- Convert base64url back to standard base64
    local b64 = input:gsub('-', '+'):gsub('_', '/')
    -- Add padding
    local remainder = #b64 % 4
    if remainder == 2 then
        b64 = b64 .. '=='
    elseif remainder == 3 then
        b64 = b64 .. '='
    end
    return encoding.decode_base64(b64)
end

local function jwt_sign(payload)
    local secret = config.oauth_jwt_secret or config.secret
    local header = { alg = 'HS256', typ = 'JWT' }
    local header_b64 = base64url_encode(cjson.encode(header))
    local payload_b64 = base64url_encode(cjson.encode(payload))
    local signing_input = header_b64 .. '.' .. payload_b64
    local signature = encoding.hmac_sha256(secret, signing_input)
    local signature_b64 = base64url_encode(signature)
    return signing_input .. '.' .. signature_b64
end

local function jwt_verify(token)
    local secret = config.oauth_jwt_secret or config.secret
    local parts = {}
    for part in token:gmatch('[^%.]+') do
        table.insert(parts, part)
    end
    if #parts ~= 3 then return nil, 'invalid token format' end

    local signing_input = parts[1] .. '.' .. parts[2]
    local expected_sig = base64url_encode(encoding.hmac_sha256(secret, signing_input))
    if expected_sig ~= parts[3] then return nil, 'invalid signature' end

    local payload = cjson.decode(base64url_decode(parts[2]))
    if payload.exp and payload.exp < os.time() then
        return nil, 'token expired'
    end
    return payload
end

-- Helper: generate a secure random string for codes/tokens
local function generate_code()
    return secure_token()
end

-- Helper: parse scope string into a set
local function parse_scopes(scope_str)
    local scopes = {}
    if scope_str then
        for scope in scope_str:gmatch('%S+') do
            scopes[scope] = true
        end
    end
    return scopes
end

-- Helper: validate redirect_uri matches the registered one
local function validate_redirect_uri(client, redirect_uri)
    if not redirect_uri then return false end
    -- Check against all registered URIs (comma-separated)
    for uri in client.redirect_uri:gmatch('[^,]+') do
        uri = uri:match('^%s*(.-)%s*$') -- trim whitespace
        if uri == redirect_uri then return true end
    end
    return false
end

-- Helper: build an error redirect URL
local function error_redirect(redirect_uri, error_code, description, state)
    local params = 'error=' .. util.escape(error_code)
    if description then
        params = params .. '&error_description=' .. util.escape(description)
    end
    if state then
        params = params .. '&state=' .. util.escape(state)
    end
    local separator = redirect_uri:find('?') and '&' or '?'
    return { redirect_to = redirect_uri .. separator .. params }
end

-- Helper: JSON error for token endpoint
local function oauth_error(error_code, description, status)
    return {
        layout = false,
        status = status or 400,
        json = {
            error = error_code,
            error_description = description
        }
    }
end

-- Authorization Code expiry in seconds (10 minutes)
local AUTH_CODE_EXPIRY = 600
-- Access token expiry in seconds (1 hour)
local ACCESS_TOKEN_EXPIRY = 3600
-- Refresh token expiry in seconds (30 days)
local REFRESH_TOKEN_EXPIRY = 30 * 24 * 3600
-- ID token expiry in seconds (1 hour)
local ID_TOKEN_EXPIRY = 3600

-- Build the base issuer URL
local function issuer_url(self)
    return self:build_url('')
end

-- Build ID token claims for a user
local function build_id_token(self, user, client_id, nonce, scopes)
    local now = os.time()
    local claims = {
        iss = issuer_url(self),
        sub = tostring(user.id),
        aud = client_id,
        exp = now + ID_TOKEN_EXPIRY,
        iat = now,
        auth_time = now,
    }
    if nonce then
        claims.nonce = nonce
    end
    -- Add profile claims if 'profile' scope requested
    if scopes['profile'] then
        claims.preferred_username = user.username
        claims.name = user.username
    end
    -- Add email claim if 'email' scope requested
    if scopes['email'] and user.email then
        claims.email = user.email
        claims.email_verified = user.verified or false
    end
    return claims
end

-- Build userinfo response
local function build_userinfo(user, scopes)
    local info = {
        sub = tostring(user.id),
    }
    if scopes['profile'] then
        info.preferred_username = user.username
        info.name = user.username
        if user.about then info.about = user.about end
        if user.location then info.locale = user.location end
        info.role = user.role
    end
    if scopes['email'] and user.email then
        info.email = user.email
        info.email_verified = user.verified or false
    end
    return info
end

-- ================
-- ROUTE HANDLERS
-- ================

-- GET /oauth2/authorize
-- Authorization endpoint: shows consent page or redirects with auth code
app:match('oauth_authorize', '/oauth2/authorize', respond_to({
    before = capture_errors(function (self)
        -- Validate required parameters
        if not self.params.client_id then
            yield_error({ msg = 'Missing client_id parameter', status = 400 })
        end
        if not self.params.response_type then
            yield_error({ msg = 'Missing response_type parameter', status = 400 })
        end
        if not self.params.redirect_uri then
            yield_error({ msg = 'Missing redirect_uri parameter', status = 400 })
        end

        -- Look up the client
        self.oauth_client = OAuthClients:find({ client_id = self.params.client_id })
        if not self.oauth_client then
            yield_error({ msg = 'Unknown client_id', status = 400 })
        end

        -- Validate redirect_uri
        if not validate_redirect_uri(self.oauth_client, self.params.redirect_uri) then
            yield_error({ msg = 'Invalid redirect_uri', status = 400 })
        end

        -- Only authorization code flow is supported
        if self.params.response_type ~= 'code' then
            return self:write(error_redirect(
                self.params.redirect_uri,
                'unsupported_response_type',
                'Only authorization code flow is supported',
                self.params.state
            ))
        end
    end),

    GET = capture_errors(function (self)
        -- If user is not logged in, redirect to login with return URL
        if not self.current_user then
            local oauth_params = {
                client_id = self.params.client_id,
                redirect_uri = self.params.redirect_uri,
                response_type = self.params.response_type,
                scope = self.params.scope,
                state = self.params.state,
                nonce = self.params.nonce,
            }
            local current_url = '/oauth2/authorize?' ..
                util.encode_query_string(oauth_params)
            return { redirect_to = '/login?redirect_to=' ..
                util.escape(current_url) }
        end

        -- Show consent page
        self.client_name = self.oauth_client.name
        self.client_icon = self.oauth_client.client_icon
        self.scopes = self.params.scope or 'openid'
        return { render = 'oauth/authorize' }
    end),

    POST = capture_errors(function (self)
        -- User must be logged in
        if not self.current_user then
            yield_error({ msg = 'You must be logged in', status = 401 })
        end

        -- Check if user approved or denied
        if self.params.deny then
            return self:write(error_redirect(
                self.params.redirect_uri,
                'access_denied',
                'The user denied the authorization request',
                self.params.state
            ))
        end

        -- Generate authorization code
        local code = generate_code()
        OAuthAuthorizationCodes:create({
            code = code,
            client_id = self.oauth_client.client_id,
            user_id = self.current_user.id,
            redirect_uri = self.params.redirect_uri,
            scope = self.params.scope or 'openid',
            nonce = self.params.nonce,
            created_at = db.format_date(),
        })

        -- Redirect back to client with auth code
        local redirect = self.params.redirect_uri
        local separator = redirect:find('?') and '&' or '?'
        local params = 'code=' .. util.escape(code)
        if self.params.state then
            params = params .. '&state=' .. util.escape(self.params.state)
        end
        return { redirect_to = redirect .. separator .. params }
    end),
}))

-- POST /oauth2/token
-- Token endpoint: exchanges authorization code for access/refresh/id tokens
app:match('oauth_token', '/oauth2/token', respond_to({
    POST = function (self)
        -- Parse client credentials from Authorization header or body
        local client_id = self.params.client_id
        local client_secret = self.params.client_secret

        local auth_header = self.req.headers['authorization']
        if auth_header then
            local encoded = auth_header:match('^Basic%s+(.+)$')
            if encoded then
                local decoded = encoding.decode_base64(encoded)
                if decoded then
                    local id, secret = decoded:match('^([^:]+):(.+)$')
                    if id then
                        client_id = util.unescape(id)
                        client_secret = util.unescape(secret)
                    end
                end
            end
        end

        if not client_id or not client_secret then
            return oauth_error('invalid_client', 'Missing client credentials', 401)
        end

        -- Authenticate client
        local client = OAuthClients:find({ client_id = client_id })
        if not client or client.client_secret ~= client_secret then
            return oauth_error('invalid_client', 'Invalid client credentials', 401)
        end

        local grant_type = self.params.grant_type

        if grant_type == 'authorization_code' then
            return handle_authorization_code_grant(self, client)
        elseif grant_type == 'refresh_token' then
            return handle_refresh_token_grant(self, client)
        else
            return oauth_error('unsupported_grant_type',
                'Only authorization_code and refresh_token grant types are supported')
        end
    end,
}))

function handle_authorization_code_grant(self, client)
    local code_value = self.params.code
    if not code_value then
        return oauth_error('invalid_request', 'Missing code parameter')
    end

    -- Look up authorization code
    local auth_code = OAuthAuthorizationCodes:find({ code = code_value })
    if not auth_code then
        return oauth_error('invalid_grant', 'Invalid authorization code')
    end

    -- Verify code belongs to this client
    if auth_code.client_id ~= client.client_id then
        auth_code:delete()
        return oauth_error('invalid_grant', 'Authorization code was not issued to this client')
    end

    -- Verify redirect_uri matches
    if self.params.redirect_uri and self.params.redirect_uri ~= auth_code.redirect_uri then
        auth_code:delete()
        return oauth_error('invalid_grant', 'redirect_uri mismatch')
    end

    -- Check expiry (10 minutes)
    local created_query = db.select(
        "extract(epoch from now() - ?::timestamp) as age",
        auth_code.created_at
    )[1]
    if created_query.age > AUTH_CODE_EXPIRY then
        auth_code:delete()
        return oauth_error('invalid_grant', 'Authorization code has expired')
    end

    -- Code is valid - delete it (single use)
    auth_code:delete()

    -- Look up the user
    local user = Users:find({ id = auth_code.user_id })
    if not user then
        return oauth_error('invalid_grant', 'User not found')
    end

    local scopes = parse_scopes(auth_code.scope)
    local now = os.time()

    -- Generate access token (JWT)
    local access_token = jwt_sign({
        iss = issuer_url(self),
        sub = tostring(user.id),
        aud = client.client_id,
        exp = now + ACCESS_TOKEN_EXPIRY,
        iat = now,
        scope = auth_code.scope,
        token_type = 'access_token',
    })

    -- Generate refresh token
    local refresh_token_value = generate_code()
    OAuthRefreshTokens:create({
        token = refresh_token_value,
        client_id = client.client_id,
        user_id = user.id,
        scope = auth_code.scope,
        created_at = db.format_date(),
    })

    local response = {
        access_token = access_token,
        token_type = 'Bearer',
        expires_in = ACCESS_TOKEN_EXPIRY,
        refresh_token = refresh_token_value,
        scope = auth_code.scope,
    }

    -- Include id_token if openid scope was requested
    if scopes['openid'] then
        local id_claims = build_id_token(self, user, client.client_id,
            auth_code.nonce, scopes)
        response.id_token = jwt_sign(id_claims)
    end

    return {
        layout = false,
        status = 200,
        json = response,
        headers = {
            ['Cache-Control'] = 'no-store',
            ['Pragma'] = 'no-cache',
        },
    }
end

function handle_refresh_token_grant(self, client)
    local refresh_token_value = self.params.refresh_token
    if not refresh_token_value then
        return oauth_error('invalid_request', 'Missing refresh_token parameter')
    end

    local refresh_token = OAuthRefreshTokens:find({ token = refresh_token_value })
    if not refresh_token then
        return oauth_error('invalid_grant', 'Invalid refresh token')
    end

    if refresh_token.client_id ~= client.client_id then
        return oauth_error('invalid_grant', 'Refresh token was not issued to this client')
    end

    -- Check expiry (30 days)
    local created_query = db.select(
        "extract(epoch from now() - ?::timestamp) as age",
        refresh_token.created_at
    )[1]
    if created_query.age > REFRESH_TOKEN_EXPIRY then
        refresh_token:delete()
        return oauth_error('invalid_grant', 'Refresh token has expired')
    end

    local user = Users:find({ id = refresh_token.user_id })
    if not user then
        refresh_token:delete()
        return oauth_error('invalid_grant', 'User not found')
    end

    local scopes = parse_scopes(refresh_token.scope)
    local now = os.time()

    -- Rotate refresh token
    refresh_token:delete()
    local new_refresh_token_value = generate_code()
    OAuthRefreshTokens:create({
        token = new_refresh_token_value,
        client_id = client.client_id,
        user_id = user.id,
        scope = refresh_token.scope,
        created_at = db.format_date(),
    })

    -- Generate new access token
    local access_token = jwt_sign({
        iss = issuer_url(self),
        sub = tostring(user.id),
        aud = client.client_id,
        exp = now + ACCESS_TOKEN_EXPIRY,
        iat = now,
        scope = refresh_token.scope,
        token_type = 'access_token',
    })

    local response = {
        access_token = access_token,
        token_type = 'Bearer',
        expires_in = ACCESS_TOKEN_EXPIRY,
        refresh_token = new_refresh_token_value,
        scope = refresh_token.scope,
    }

    -- Include id_token if openid scope
    if scopes['openid'] then
        local id_claims = build_id_token(self, user, client.client_id, nil, scopes)
        response.id_token = jwt_sign(id_claims)
    end

    return {
        layout = false,
        status = 200,
        json = response,
        headers = {
            ['Cache-Control'] = 'no-store',
            ['Pragma'] = 'no-cache',
        },
    }
end

-- GET /oauth2/userinfo
-- UserInfo endpoint: returns claims about the authenticated user
app:match('oauth_userinfo', '/oauth2/userinfo', respond_to({
    GET = function (self)
        return handle_userinfo(self)
    end,
    POST = function (self)
        return handle_userinfo(self)
    end,
}))

function handle_userinfo(self)
    -- Extract Bearer token from Authorization header
    local auth_header = self.req.headers['authorization']
    if not auth_header then
        return oauth_error('invalid_request', 'Missing Authorization header', 401)
    end

    local token = auth_header:match('^Bearer%s+(.+)$')
    if not token then
        return oauth_error('invalid_request', 'Invalid Authorization header format', 401)
    end

    -- Verify access token
    local payload, err = jwt_verify(token)
    if not payload then
        return oauth_error('invalid_token', err or 'Invalid access token', 401)
    end

    if payload.token_type ~= 'access_token' then
        return oauth_error('invalid_token', 'Not an access token', 401)
    end

    -- Look up user
    local user = Users:find({ id = tonumber(payload.sub) })
    if not user then
        return oauth_error('invalid_token', 'User not found', 401)
    end

    local scopes = parse_scopes(payload.scope)
    local info = build_userinfo(user, scopes)

    return {
        layout = false,
        status = 200,
        json = info,
    }
end

-- GET /.well-known/openid-configuration
-- OpenID Connect Discovery document
app:get('oidc_discovery', '/.well-known/openid-configuration', function (self)
    local base = issuer_url(self)
    return {
        layout = false,
        status = 200,
        json = {
            issuer = base,
            authorization_endpoint = base .. 'oauth2/authorize',
            token_endpoint = base .. 'oauth2/token',
            userinfo_endpoint = base .. 'oauth2/userinfo',
            token_introspection_endpoint = base .. 'oauth2/introspect',
            scopes_supported = { 'openid', 'profile', 'email' },
            response_types_supported = { 'code' },
            grant_types_supported = { 'authorization_code', 'refresh_token' },
            subject_types_supported = { 'public' },
            id_token_signing_alg_values_supported = { 'HS256' },
            token_endpoint_auth_methods_supported = {
                'client_secret_basic', 'client_secret_post'
            },
            claims_supported = {
                'sub', 'iss', 'aud', 'exp', 'iat', 'nonce',
                'name', 'preferred_username', 'email', 'email_verified',
                'role',
            },
        },
    }
end)

-- POST /oauth2/introspect
-- Token introspection endpoint (RFC 7662)
app:match('oauth_introspect', '/oauth2/introspect', respond_to({
    POST = function (self)
        -- Authenticate client
        local client_id = self.params.client_id
        local client_secret = self.params.client_secret

        local auth_header = self.req.headers['authorization']
        if auth_header then
            local encoded = auth_header:match('^Basic%s+(.+)$')
            if encoded then
                local decoded = encoding.decode_base64(encoded)
                if decoded then
                    local id, secret = decoded:match('^([^:]+):(.+)$')
                    if id then
                        client_id = util.unescape(id)
                        client_secret = util.unescape(secret)
                    end
                end
            end
        end

        if not client_id or not client_secret then
            return oauth_error('invalid_client', 'Missing client credentials', 401)
        end

        local client = OAuthClients:find({ client_id = client_id })
        if not client or client.client_secret ~= client_secret then
            return oauth_error('invalid_client', 'Invalid client credentials', 401)
        end

        local token = self.params.token
        if not token then
            return { layout = false, status = 200, json = { active = false } }
        end

        -- Try to verify the token as a JWT access token
        local payload, err = jwt_verify(token)
        if not payload then
            return { layout = false, status = 200, json = { active = false } }
        end

        if payload.token_type ~= 'access_token' then
            return { layout = false, status = 200, json = { active = false } }
        end

        -- Verify the token was issued to the requesting client
        if payload.aud ~= client.client_id then
            return { layout = false, status = 200, json = { active = false } }
        end

        local user = Users:find({ id = tonumber(payload.sub) })
        if not user then
            return { layout = false, status = 200, json = { active = false } }
        end

        return {
            layout = false,
            status = 200,
            json = {
                active = true,
                sub = payload.sub,
                client_id = payload.aud,
                username = user.username,
                scope = payload.scope,
                exp = payload.exp,
                iat = payload.iat,
                iss = payload.iss,
                token_type = 'Bearer',
            },
        }
    end,
}))

-- POST /oauth2/revoke
-- Token revocation endpoint (RFC 7009)
app:match('oauth_revoke', '/oauth2/revoke', respond_to({
    POST = function (self)
        -- Authenticate client
        local client_id = self.params.client_id
        local client_secret = self.params.client_secret

        local auth_header = self.req.headers['authorization']
        if auth_header then
            local encoded = auth_header:match('^Basic%s+(.+)$')
            if encoded then
                local decoded = encoding.decode_base64(encoded)
                if decoded then
                    local id, secret = decoded:match('^([^:]+):(.+)$')
                    if id then
                        client_id = util.unescape(id)
                        client_secret = util.unescape(secret)
                    end
                end
            end
        end

        if not client_id or not client_secret then
            return oauth_error('invalid_client', 'Missing client credentials', 401)
        end

        local client = OAuthClients:find({ client_id = client_id })
        if not client or client.client_secret ~= client_secret then
            return oauth_error('invalid_client', 'Invalid client credentials', 401)
        end

        local token = self.params.token
        if token then
            -- Try to revoke as refresh token
            local refresh = OAuthRefreshTokens:find({ token = token })
            if refresh and refresh.client_id == client.client_id then
                refresh:delete()
            end
            -- For access tokens (JWTs), we can't truly revoke them since
            -- they are stateless. The token will expire naturally.
            -- A production system might use a token blacklist here.
        end

        -- RFC 7009: always return 200 regardless of whether token existed
        return {
            layout = false,
            status = 200,
            json = {},
        }
    end,
}))

-- Admin endpoints for managing OAuth clients

-- GET /oauth2/clients
-- List all OAuth clients (admin only)
app:get('oauth_clients_list', '/oauth2/clients', capture_errors(function (self)
    assert_admin(self)
    local clients = OAuthClients:select('order by created_at desc')
    -- Redact client secrets in list view
    for _, client in ipairs(clients) do
        client.client_secret = '***'
    end
    return jsonResponse(clients)
end))

-- POST /oauth2/clients
-- Register a new OAuth client (admin only)
app:post('oauth_clients_create', '/oauth2/clients', capture_errors(function (self)
    assert_admin(self)

    if not self.params.name or self.params.name == '' then
        yield_error({ msg = 'Client name is required', status = 400 })
    end
    if not self.params.redirect_uri or self.params.redirect_uri == '' then
        yield_error({ msg = 'Redirect URI is required', status = 400 })
    end

    local client_id = secure_salt() .. secure_salt()
    local client_secret = secure_token()

    local client = OAuthClients:create({
        name = self.params.name,
        client_id = client_id,
        client_secret = client_secret,
        redirect_uri = self.params.redirect_uri,
        client_icon = self.params.client_icon,
        owner_id = self.current_user.id,
        created_at = db.format_date(),
        updated_at = db.format_date(),
    })

    return jsonResponse({
        id = client.id,
        name = client.name,
        client_id = client.client_id,
        client_secret = client.client_secret,
        redirect_uri = client.redirect_uri,
        client_icon = client.client_icon,
        created_at = client.created_at,
    })
end))

-- DELETE /oauth2/clients/:client_id
-- Delete an OAuth client (admin only)
app:match('oauth_client_delete', '/oauth2/clients/:oauth_client_id',
    respond_to({
        DELETE = capture_errors(function (self)
            assert_admin(self)
            local client = OAuthClients:find({
                client_id = self.params.oauth_client_id
            })
            if not client then
                yield_error({ msg = 'Client not found', status = 404 })
            end
            -- Clean up related tokens and codes
            db.delete('oauth_authorization_codes',
                { client_id = client.client_id })
            db.delete('oauth_refresh_tokens',
                { client_id = client.client_id })
            client:delete()
            return okResponse('Client deleted')
        end),
    })
)
