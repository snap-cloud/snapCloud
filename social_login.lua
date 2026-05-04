-- Social Login (External Identity Providers)
-- ===========================================
--
-- Implements "Sign in with Google" and a general identity-linking framework.
-- Other providers (GitHub, Microsoft, etc.) can be added following the same
-- pattern.
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
local http = require('resty.http')

local Users = package.loaded.Users
local Identities = package.loaded.Identities

require('passwords')

-- =========================================================================
-- Google OIDC Configuration
-- =========================================================================

local GOOGLE_AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
local GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'
local GOOGLE_USERINFO_URL = 'https://openidconnect.googleapis.com/v1/userinfo'

-- Build the callback URL for the current environment
local function google_callback_url(self)
    return self:build_url('/auth/google/callback')
end

-- Generate a random state parameter to prevent CSRF
local function generate_state()
    return secure_salt() .. secure_salt()
end

-- =========================================================================
-- Helper: fetch tokens from Google token endpoint
-- =========================================================================
local function exchange_google_code(self, code)
    local httpc = http.new()
    httpc:set_timeout(10000)

    local res, err = httpc:request_uri(GOOGLE_TOKEN_URL, {
        method = 'POST',
        body = util.encode_query_string({
            code = code,
            client_id = config.google_client_id,
            client_secret = config.google_client_secret,
            redirect_uri = google_callback_url(self),
            grant_type = 'authorization_code',
        }),
        headers = {
            ['Content-Type'] = 'application/x-www-form-urlencoded',
        },
    })

    if not res then
        return nil, 'Failed to contact Google: ' .. (err or 'unknown error')
    end

    if res.status ~= 200 then
        return nil, 'Google token exchange failed (HTTP ' .. res.status .. ')'
    end

    return cjson.decode(res.body)
end

-- =========================================================================
-- Helper: fetch user profile from Google userinfo endpoint
-- =========================================================================
local function fetch_google_userinfo(access_token)
    local httpc = http.new()
    httpc:set_timeout(10000)

    local res, err = httpc:request_uri(GOOGLE_USERINFO_URL, {
        method = 'GET',
        headers = {
            ['Authorization'] = 'Bearer ' .. access_token,
        },
    })

    if not res then
        return nil, 'Failed to contact Google userinfo: ' .. (err or 'unknown')
    end

    if res.status ~= 200 then
        return nil, 'Google userinfo request failed (HTTP ' .. res.status .. ')'
    end

    return cjson.decode(res.body)
end

-- =========================================================================
-- ROUTES
-- =========================================================================

-- GET /auth/google
-- Initiates the Google Sign-In flow by redirecting the user to Google.
app:get('google_auth', '/auth/google', function (self)
    if not config.google_client_id then
        yield_error({ msg = 'Google Sign-In is not configured', status = 503 })
    end

    local state = generate_state()
    self.session.google_oauth_state = state

    local params = util.encode_query_string({
        client_id = config.google_client_id,
        redirect_uri = google_callback_url(self),
        response_type = 'code',
        scope = 'openid email profile',
        state = state,
        prompt = 'select_account',
    })

    return { redirect_to = GOOGLE_AUTH_URL .. '?' .. params }
end)

-- GET /auth/google/callback
-- Handles the OAuth2 callback from Google after user consent.
app:get('google_callback', '/auth/google/callback', capture_errors(function (self)
    -- Verify state to prevent CSRF
    if not self.params.state or
            self.params.state ~= self.session.google_oauth_state then
        yield_error({ msg = 'Invalid state parameter. Please try again.',
            status = 400 })
    end
    self.session.google_oauth_state = nil

    -- Check for error from Google
    if self.params.error then
        yield_error({
            msg = 'Google Sign-In was cancelled or failed: ' ..
                (self.params.error_description or self.params.error),
            status = 400
        })
    end

    if not self.params.code then
        yield_error({ msg = 'Missing authorization code from Google',
            status = 400 })
    end

    -- Exchange code for tokens
    local tokens, token_err = exchange_google_code(self, self.params.code)
    if not tokens then
        yield_error({ msg = token_err, status = 502 })
    end

    -- Fetch user profile from Google
    local google_user, profile_err = fetch_google_userinfo(tokens.access_token)
    if not google_user then
        yield_error({ msg = profile_err, status = 502 })
    end

    -- google_user contains: sub, email, email_verified, name, picture, etc.
    local google_id = google_user.sub
    local google_email = google_user.email

    -- Check if this Google identity is already linked to a Snap! account
    local identity = Identities:find({
        provider = 'google',
        external_id = google_id,
    })

    if identity then
        -- Already linked -- log the user in directly
        identity:update({ last_used_at = db.format_date() })
        local user = Users:find({ id = identity.user_id })
        if not user then
            yield_error({ msg = 'Linked account no longer exists', status = 404 })
        end
        self.session.username = user.username
        self.session.persist_session = 'true'
        user:update({ last_login_at = db.format_date() })
        return { redirect_to = '/' }
    end

    -- No linked identity found.
    -- If user is already logged in, link directly (no password needed since
    -- they already authenticated via their session).
    if self.current_user then
        Identities:create({
            user_id = self.current_user.id,
            provider = 'google',
            external_id = google_id,
            verified = true,
            display_name = google_user.name,
            email = google_email,
            avatar_url = google_user.picture,
            created_at = db.format_date(),
            updated_at = db.format_date(),
            last_used_at = db.format_date(),
        })
        return { redirect_to = '/' }
    end

    -- User is not logged in and identity is not linked.
    -- Check if a Snap! account with the same email exists.
    local existing_users = Users:select('where email = ? limit 1', google_email)
    local existing_user = existing_users and existing_users[1]

    if existing_user then
        -- An account with this email exists. We need the user to verify
        -- ownership by entering their Snap! password before linking.
        -- Store the Google info in the session for the link-accounts page.
        self.session.pending_link = {
            provider = 'google',
            external_id = google_id,
            email = google_email,
            display_name = google_user.name,
            avatar_url = google_user.picture,
            username = existing_user.username,
        }
        return { redirect_to = '/auth/link_account' }
    end

    -- No existing account with this email. Store info and redirect to a
    -- page where the user can either link to an existing account with a
    -- different email or understand they need to sign up first.
    self.session.pending_link = {
        provider = 'google',
        external_id = google_id,
        email = google_email,
        display_name = google_user.name,
        avatar_url = google_user.picture,
        username = nil, -- no match found
    }
    return { redirect_to = '/auth/link_account' }
end))

-- GET /auth/link_account
-- Shows a form to verify account ownership before linking an external identity.
app:get('link_account', '/auth/link_account', capture_errors(function (self)
    if not self.session.pending_link then
        return { redirect_to = '/login' }
    end

    self.pending_link = self.session.pending_link
    return { render = 'auth/link_account' }
end))

-- POST /auth/link_account
-- Verifies the user's password and links the external identity.
app:post('link_account_post', '/auth/link_account', capture_errors(function (self)
    local pending = self.session.pending_link
    if not pending then
        yield_error({ msg = 'No pending identity link. Please start over.',
            status = 400 })
    end

    local username = self.params.username
    local password = self.params.password

    if not username or username == '' then
        yield_error({ msg = 'Username is required', status = 400 })
    end
    if not password or password == '' then
        yield_error({ msg = 'Password is required', status = 400 })
    end

    -- Look up the user
    local user = Users:find({ username = username:lower() })
    if not user then
        yield_error({ msg = 'Invalid username or password', status = 403 })
    end

    -- Verify password using the multi-version scheme
    local password_valid = verify_password(
        password,
        user.password,
        user.salt,
        user.password_version
    )
    if not password_valid then
        yield_error({ msg = 'Invalid username or password', status = 403 })
    end

    -- Password verified -- link the identity
    Identities:create({
        user_id = user.id,
        provider = pending.provider,
        external_id = pending.external_id,
        verified = true,
        display_name = pending.display_name,
        email = pending.email,
        avatar_url = pending.avatar_url,
        created_at = db.format_date(),
        updated_at = db.format_date(),
        last_used_at = db.format_date(),
    })

    -- Clear pending state and log them in
    self.session.pending_link = nil
    self.session.username = user.username
    self.session.persist_session = 'true'
    user:update({ last_login_at = db.format_date() })

    -- Upgrade password to bcrypt if still on legacy scheme
    upgrade_password_to_bcrypt(user, password)

    return { redirect_to = '/' }
end))
