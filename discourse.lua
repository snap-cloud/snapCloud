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

local sso_secret = config.discourse_sso_secret

app:get('/discourse-sso', capture_errors(function(self)
    -- params are automatically unescaped.
    local payload = self.params.sso
    local signature = self.params.sig
    local computed_signature = create_signature(sso_secret, payload)

    if computed_signature ~= signature then
        return errorResponse('Signature does not match. Please try again')
    end

    if not self.session.username then
        return 'Please login through Snap! then return to the forum.'
        -- redirect to login
        -- make sure to include params.
    end

    local decoded_payload = encoding.decode_base64(payload)
    local parsed_payload = util.parse_query_string(decoded_payload)
    local user = Users:select('where username = ? limit 1',
            self.session.username,
            { fields = 'id, username, verified, isadmin, email' })[1]
    local redirect_params = {
        external_id = user.id,
        username = user.username,
        require_activation = not user.verified,
        email = user.email,
        admin = user.isadmin,
        nonce = parsed_payload.nonce
    }
    local discourse = parsed_payload.return_sso_url
    local new_payload = util.encode_query_string(redirect_params)
    local base64_paylod = encoding.encode_base64(new_payload)
    local url_payload = util.escape(base64_paylod)
    local new_signature = create_signature(sso_secret, base64_paylod)
    local final_url = discourse .. '?sso=' .. url_payload .. '&sig=' .. new_signature
    return { redirect_to = final_url }
end))

function create_signature(secret, payload)
    return crypto.hmac.digest('sha256', payload, secret)
end

function create_payload(user, nonce)

end

function create_redirect_url(discourse_url, payload, signature)
end
