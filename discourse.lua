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
local hmac = require("crypto.hmac")

local sso_secret = 'd836444a9e4084d5b224a60c208dce14'
-- TEST URL: http://localhost:8080/discourse-sso?sso=bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGI%3D%0A&sig=2828aa29899722b35a2f191d34ef9b3ce695e0e6eeec47deb46d588d70c7cb56

app:get('/discourse-sso', function(self)
    local payload = self.params.sso
    local sig = self.params.sig
    local unescaped_payload = util.unescape(payload)
    local decoded_sig = encoding.decode_base64(sig)
    local decoded_payload = encoding.decode_base64(payload)
    local payload_json = util.parse_query_string(decoded_payload)

    local nonce = payload_json.nonce
    local partial_payload = 'nonce='.. nonce
    local base64_payload = encoding.encode_base64(partial_payload)
    local urlencode_payload = util.escape(payload)
    local validation_sig = create_signature(sso_secret, unescaped_payload)
    local base64_sig = encoding.encode_base64(validation_sig)
    -- local hmacSecret = hmac_256()
    return okResponse({
        payload_json = payload_json,
        unescaped_payload = unescaped_payload,
        base64_payload = base64_payload,
        match_payload = urlencode_payload == payload,
        base64_sig = base64_sig,
        valid =  validation_sig == sig,
        sig = sig,
        payload = payload,
        partial_payload = partial_payload,
        expected_payload = 'nonce=cb68251eefb5211e58c00ff1395f0c0b',
        expected_base64 = 'bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGI=\n',
        expected_url_encode = 'bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGI%3D%0A'
        -- payload_json = payload_json
    })
end)

-- 1. Validate the signature, ensure that HMAC-SHA256 of sso_secret, PAYLOAD is equal to the sig
function create_signature(secret, payload)
    return hmac.digest('sha256', payload, secret)
end
