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
local util = package.loaded.util
local crypto = package.loaded.crypto
-- local encoding = require("lapis.util.encoding")

-- require 'responses'
-- require 'validation'

local sso_secret = 'd836444a9e4084d5b224a60c208dce14'
-- TEST URL: http://localhost:8080/discourse-sso?sso=bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGI%3D%0A&sig=2828aa29899722b35a2f191d34ef9b3ce695e0e6eeec47deb46d588d70c7cb56

app:get('/discourse-sso', function(self)
    local payload = self.params.sso
    local sig = self.params.sig
    local unescaped_payload = util.unescape(payload)
    local validation_sig = create_signature(sso_secret, unescaped_payload)
    return okResponse({
        valid =  validation_sig == sig
    })
end)

function create_signature(secret, payload)
    return crypto.hmac.digest('sha256', payload, secret)
end
