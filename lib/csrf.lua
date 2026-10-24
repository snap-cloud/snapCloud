-- CSRF token validation hardening
-- ===============================
--
-- Written by Michael Ball
--
-- Copyright (C) 2026 by Michael Ball
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
--
--
-- Why this file exists
-- --------------------
--
-- lapis.csrf.validate_token (through lapis 1.20.0) assumes that
-- req.params.csrf_token is a string. Lapis expands bracketed parameter names
-- such as `csrf_token[x]=y` into tables before the action runs, so a request
-- shaped that way makes validate_token call string methods on a table. The
-- request dies with a 500 and a Sentry event instead of a clean "invalid
-- token" response. Until lapis guards for this upstream we wrap the function
-- here, the same way lib/cookies.lua does: patch the module table lapis
-- exports rather than carry a patched copy of lapis.
--
-- This is a robustness fix only. Snap!Cloud's real CSRF defence is the Origin
-- check in app.lua's before_filter; lapis tokens are used on the password
-- reset form (controllers/user.lua) and nowhere else.

local csrf = require('lapis.csrf')
local lapis_validate_token = csrf.validate_token

csrf.validate_token = function (req, callback)
    local token = req.params and req.params.csrf_token
    if token ~= nil and type(token) ~= 'string' then
        return nil, 'csrf: invalid token'
    end
    return lapis_validate_token(req, callback)
end

-- lapis' assert_token closes over its own local validate_token and would
-- bypass the guard above, so route it through the module field instead.
csrf.assert_token = function (...)
    local assert_error = require('lapis.application').assert_error
    return assert_error(csrf.validate_token(...))
end

return csrf
