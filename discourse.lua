-- Discourse SSO module
-- ==========
--
-- Implements a login endpoint for the Discourse forum.
--
-- Written by Bernat Romagosa
--
-- Copyright (C) 2018 by Michael Ball
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
local util = package.loaded.util
local crypto = package.loaded.crypto
local config = package.loaded.config
local encoding = require("lapis.util.encoding")

app:get('/discourse-sso', capture_errors(function(self)
    -- params are automatically unescaped.
    local payload = self.params.sso
    local signature = self.params.sig
    local sso_secret = config.discourse_sso_secret
    local computed_signature = create_signature(sso_secret, payload)

    if computed_signature ~= signature then
        return errorResponse('Signature does not match. Please try again')
    end

    if not self.session and not self.session.username then
        return errorResponse('Please login through Snap! then return to the forum.')
        -- redirect to login
        -- make sure to include params.
    end

    local request_payload = extract_payload(payload)
    local user = Users:select('where username = ? limit 1',
            self.session.username,
            { fields = 'id, username, verified, isadmin, email' })[1]
    local final_url = create_redirect_url(
        parsed_payload.return_sso_url,
        build_payload(user, request_payload.nonce),
        create_signature(sso_secret, response_paylod)
    )

    -- don't redirect in development so you don't mess up your forum account.
    if config._name == 'development' then return final_url end
    return { redirect_to = final_url }
end))

function create_signature(secret, payload)
    return crypto.hmac.digest('sha256', payload, secret)
end

function extract_payload(payload)
    return util.parse_query_string(encoding.decode_base64(payload))
end

-- Base64 encode the required discourse params.
-- "require_activation" is a special discourse flag,
-- for user's whose email is not verified. It enables additional restrictions.
function build_payload(user, nonce)
    local params = {
        external_id = user.id,
        username = user.username,
        email = user.email,
        require_activation = not user.verified,
        admin = user.isadmin,
        nonce = nonce
    }
    return encoding.encode_base64(util.encode_query_string(params))
end

function create_redirect_url(discourse_url, payload, signature)
    local url_payload = util.escape(base64_paylod)
    return discourse_url .. '?sso=' .. url_payload .. '&sig=' .. signature
end
