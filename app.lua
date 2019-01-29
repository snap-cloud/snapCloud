-- Snap Cloud
-- ==========
--
-- A cloud backend for Snap!
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


-- Packaging everything so it can be accessed from other modules

local lapis = require 'lapis'
package.loaded.app = lapis.Application()
package.loaded.db = require 'lapis.db'
package.loaded.app_helpers = require 'lapis.application'
package.loaded.yield_error = package.loaded.app_helpers.yield_error
package.loaded.validate = require 'lapis.validate'
package.loaded.Model = require('lapis.db.model').Model
package.loaded.util = require 'lapis.util'
package.loaded.cached = require('lapis.cache').cached
package.loaded.resty_sha512 = require 'resty.sha512'
package.loaded.resty_string = require 'resty.string'
package.loaded.resty_random = require 'resty.random'
package.loaded.config = require('lapis.config').get()
package.loaded.rollbar = require('resty.rollbar')

require 'models'
require 'responses'
require 'maintenance'

local app = package.loaded.app
local config = package.loaded.config
local Users = package.loaded.Users

-- Track exceptions
local rollbar = package.loaded.rollbar
rollbar.set_token(config.rollbar_token)
rollbar.set_environment(config._name)

-- Store whitelisted domains
local domain_allowed = require 'cors'
-- Utility functions
local helpers = require 'helpers'

-- wrap the lapis capture errors to provide our own custom error handling
-- just do: yield_error({msg = 'oh no', status = 401})
local lapis_capture_errors = package.loaded.app_helpers.capture_errors
package.loaded.capture_errors = function(fn)
    return lapis_capture_errors({
        on_error = function(self)
            local error = self.errors[1]
            if type(error) == 'table' then
                return errorResponse(error.msg, error.status)
            else
                return errorResponse(error, 400)
            end
        end,
        fn
    })
end

-- Make cookies persistent
app.cookie_attributes = function(self)
    local date = require("date")
    local expires = date(true):adddays(365):fmt("${http}")
    return "Expires=" .. expires .. "; Path=/; HttpOnly;"
end

-- Before filter
app:before_filter(function (self)
    -- unescape all parameters
    for k, v in pairs(self.params) do
        self.params[k] = package.loaded.util.unescape(v)
    end

    if self.params.username then
        self.params.username = self.params.username:lower()
        self.queried_user = Users:find(self.params.username)
    end

    if self.session.username then
        self.current_user = Users:find(self.session.username)
    else
        self.session.username = ''
        self.current_user = nil
    end

    if self.params.matchtext then
        self.params.matchtext = '%' .. self.params.matchtext .. '%'
    end

    -- Set Access Control header
    local domain = helpers.domain_name(self.req.headers.origin)
    if self.req.headers.origin and domain_allowed[domain] then
        self.res.headers['Access-Control-Allow-Origin'] = self.req.headers.origin
        self.res.headers['Access-Control-Allow-Credentials'] = 'true'
        self.res.headers['Vary'] = 'Origin'
    end
end)


-- This module only takes care of the index endpoint

app:get('/', function(self)
    return { redirect_to = self:build_url('snap/snap.html') }
end)

app:get('/site', function(self)
    return { redirect_to = self:build_url('site/index.html') }
end)

function app:handle_404()
    return errorResponse("Failed to find resource: " .. self.req.cmd_url, 404)
end

function app:handle_error(err, trace)
    local current_user = self.original_request.current_user
    user_params = current_user and current_user:rollbar_params() or {}

    rollbar.set_person(user_params)
    rollbar.set_custom_trace(err .. "\n\n" .. trace)
    rollbar.report(rollbar.ERR, helpers.normalize_error(err))
    return errorResponse(err, 500)
end

-- The API is implemented in the api.lua file
require 'api'
require 'discourse'

return app
