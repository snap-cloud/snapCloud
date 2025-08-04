-- Discourse SSO module
-- ====================
--
-- Implements a login endpoint for the Discourse forum.
-- SSO will use the current user session if one exists
-- Otherwise, it will redirect the user to the login page.
-- Once the request is verified, the user is redirected to the forum.
-- https://meta.discourse.org/t/official-single-sign-on-for-discourse-sso/13045
--
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa and Michael Ball
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
local Users = package.loaded.Users
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local util = package.loaded.util
local config = package.loaded.config
local encoding = require("lapis.util.encoding")
local resty_string = package.loaded.resty_string
local capitalize = require('lib.util').capitalize

local create_signature, extract_payload, build_payload, create_redirect_url

app:get('/api/v1/discourse-sso', capture_errors(function(self)
    if self.session.username == '' then
        local signin_url = '/login?redirect_to='
        local encoded_params = util.encode_query_string(self.params)
        local redirect_path = util.escape('/api/v1/discourse-sso?' .. encoded_params)
        return { redirect_to = signin_url .. redirect_path }
    end

    -- params are automatically unescaped.
    local payload = self.params.sso
    local signature = self.params.sig

    if not signature or not payload then
        local message = 'Please go back and try again. '
        if not signature then
            message = message .. '(Request signature is missing.)'
        else
            message = message .. '(Request payload is missing.)'
        end
        yield_error({ msg = message, status = 422 })
    end

    local computed_signature = create_signature(payload)
    if computed_signature ~= signature then
        yield_error({ msg = 'Signature does not match. Please try again.',
                     status = 422 })
    end

    local request_payload = extract_payload(payload)
    local user = Users:select('where username = ? limit 1',
            self.session.username,
            { fields = 'id, username, verified, role, email, unique_email' })[1]

    -- ensure user exists
    if not user then
        yield_error({ msg = 'User not found.', status = 404 })
    end

    if user:cannot_access_forum() then
        yield_error({ msg = capitalize(user.role) .. ' users cannot use the forum.', status = 403 })
    end

    local response_payload = build_payload(user, request_payload)
    local final_url = create_redirect_url(request_payload.return_sso_url,
                                          response_payload)

    -- don't redirect in development so you don't mess up your forum account.
    if config._name == 'development' then return final_url end
    return { redirect_to = final_url }
end))

function create_signature(payload)
    local secret = config.discourse_sso_secret
    return resty_string.to_hex(encoding.hmac_sha256(secret, payload))
end

function extract_payload(payload)
    return util.parse_query_string(encoding.decode_base64(payload))
end

-- Base64 encode the required discourse params.
-- "require_activation" is a special discourse flag,
-- for user's whose email is not verified. It enables additional restrictions.
function build_payload(user, request_payload)
    local params = {
        external_id = user.id,
        username = user.username,
        email = user:discourse_email(),
        require_activation = not user.verified,
        admin = user:isadmin(),
        moderator = user:ismoderator(),
        nonce = request_payload.nonce,
        return_sso_url = request_payload.return_sso_url
    }
    return encoding.encode_base64(util.encode_query_string(params))
end

function create_redirect_url(discourse_url, payload)
    local encoded_payload = util.escape(payload)
    local signature = create_signature(payload)
    return discourse_url .. '?sso=' .. encoded_payload .. '&sig=' .. signature
end
