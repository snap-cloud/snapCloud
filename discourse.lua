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
local db = package.loaded.db
local Users = package.loaded.Users
local app_helpers = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local util = package.loaded.util
local crypto = package.loaded.crypto
local encoding = require("lapis.util.encoding")

-- require 'responses'
-- require 'validation'

-- local sso_secret = 'd836444a9e4084d5b224a60c208dce14'
-- TEST URL: http://localhost:8080/discourse-sso?sso=bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGI%3D%0A&sig=2828aa29899722b35a2f191d34ef9b3ce695e0e6eeec47deb46d588d70c7cb56
local sso_secret = '1234567890'
-- Second URL secret  http://localhost:8080/discourse-sso?sso=bm9uY2U9NTdjM2M1MjkyYWQyN2E0ZTc5Y2ZmNzYyYTU4NWRiZjMmcmV0dXJuX3Nzb191cmw9aHR0cHMlM0ElMkYlMkZzbmFwLWZvcnVtLmNzMTAub3JnJTJGc2Vzc2lvbiUyRnNzb19sb2dpbg%3D%3D&sig=aef72abe528f4ed2342e3c27bf78994578bbe83bc1244489fe113f0b57e0a22c
app:get('/discourse-sso', capture_errors(function(self)
    -- params are automatically unescaped.
    local payload = self.params.sso
    local signature = self.params.sig
    local computed_signature = create_signature(sso_secret, payload)
    local decoded_payload = encoding.decode_base64(payload)
    local parsed_payload = util.parse_query_string(decoded_payload)

    if computed_signature ~= signature then
        return errorResponse('Signature does not match. Please try again')
    end

    if not self.session.username then
        -- redirect to login
        -- make sure to include params.
    else
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
    end

    -- return okResponse({
    --     valid = validation_sig == sig
    -- })
end))

function create_signature(secret, payload)
    return crypto.hmac.digest('sha256', payload, secret)
end

function create_payload(user, nonce)

end

function create_redirect_url(discourse_url, payload, signature)
end
