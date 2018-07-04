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
local app_helpers = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local validate = package.loaded.validate
local Model = package.loaded.Model
local util = package.loaded.util
local respond_to = package.loaded.respond_to
local json_params = package.loaded.json_params
local cached = package.loaded.cached
local resty_string = package.loaded.resty_string
local encoding = require("lapis.util.encoding")

-- require 'responses'
require 'validation'
require 'crypto'

local sso_secret = 'snap'
-- TEST URL: http://localhost:8080/discourse-sso?sso=bm9uY2U9NjM3MDljMmM1NmEzYmFkZGFkNmMyMWYyMjk0ZTljM2QmcmV0dXJuX3Nzb191cmw9aHR0cHMlM0ElMkYlMkZzbmFwLWZvcnVtLmNzMTAub3JnJTJGc2Vzc2lvbiUyRnNzb19sb2dpbg%3D%3D&sig=adbe372e7179b9064bdc27641433f3feb160d0766c8aaed0019b59ff4ab66fbe
-- "decoded_payload":"nonce=63709c2c56a3baddad6c21f2294e9c3d&return_sso_url=https%3A%2F%2Fsnap-forum.cs10.org%2Fsession%2Fsso_login"}
app:get('/discourse-sso', function(self)
    local payload = self.params.sso
    local sig = self.params.sig
    local decoded_payload = encoding.decode_base64(payload)
    local validation_sig = create_signature(sso_secret, payload)
    -- local hmacSecret = hmac_256()
    return okResponse({
        validation_sig = validation_sig,
        valid =  validation_sig == sig,
        sig = sig,
        payload = payload,
        payload_json = util.parse_query_string(decoded_payload)
    })
end)

-- 1. Validate the signature, ensure that HMAC-SHA256 of sso_secret, PAYLOAD is equal to the sig
function create_signature(secret, payload)
    print(encoding.hmac_sha256(secret, payload))
    return encoding.hmac_sha256(secret, payload)
end
