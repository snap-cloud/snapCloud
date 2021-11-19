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

-- Mute annoying _G guard warnings
require 'writeguardmuter'

-- Packaging everything so it can be accessed from other modules
local lapis = require 'lapis'
package.loaded.app = lapis.Application()
package.loaded.db = require 'lapis.db'
package.loaded.app_helpers = require 'lapis.application'
package.loaded.json_params = package.loaded.app_helpers.json_params
package.loaded.yield_error = package.loaded.app_helpers.yield_error
package.loaded.validate = require 'lapis.validate'
package.loaded.Model = require('lapis.db.model').Model
package.loaded.util = require('lapis.util')
package.loaded.respond_to = package.loaded.app_helpers.respond_to
package.loaded.cached = require('lapis.cache').cached
package.loaded.resty_sha512 = require "resty.sha512"
package.loaded.resty_string = require "resty.string"
package.loaded.resty_random = require "resty.random"
package.loaded.config = require("lapis.config").get()
package.loaded.disk = require('disk')
package.loaded.component = require 'component'

local app = package.loaded.app
local config = package.loaded.config

-- Track exceptions, exposes raven, rollbar, and normalize_error
local exceptions = require('lib.exceptions')
-- Store whitelisted domains
local domain_allowed = require('cors')
-- Utility functions
local date = require("date")

string.from_sql_date = function (sql_date)
    -- Formats an SQL date into (i.e.) November 21, 2021
    local month_names = { 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December' }
    if (sql_date == nil) then return 'never' end
    local actual_date = date(sql_date)
    return month_names[actual_date:getmonth()] ..  ' ' ..
        actual_date:getday() ..  ', ' ..  actual_date:getyear()
end

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

require 'models'
require 'responses'

-- Make cookies persistent
app.cookie_attributes = function(self)
    local expires = date(true):adddays(365):fmt("${http}")
    local secure = " " .. "Secure"
    local sameSite = "None"
    if (config._name == 'development') then
        secure = ""
        sameSite = "Lax"
    end
    return "Expires=" .. expires .. "; Path=/; HttpOnly; SameSite=" .. sameSite .. ";" .. secure
end

-- Remove the protocol and port from a URL
local function domain_name(url)
    if not url then
        return
    end
    return url:gsub('https*://', ''):gsub(':%d+$', '')
end

-- Before filter
app:before_filter(function (self)
    local ip_entry = package.loaded.BannedIPs:find(ngx.var.remote_addr)
    if (ip_entry and ip_entry.offense_count > 2) then
        self:write(errorResponse('Your IP has been banned from the system', 403))
        return
    end

    -- Set Access Control header
    local domain = domain_name(self.req.headers.origin)
    if self.req.headers.origin and domain_allowed[domain] then
        self.res.headers['Access-Control-Allow-Origin'] = self.req.headers.origin
        self.res.headers['Access-Control-Allow-Credentials'] = 'true'
        self.res.headers['Vary'] = 'Origin'
    end

    if ngx.req.get_method() == 'OPTIONS' then
        return -- avoid any unnecessary work for CORS pre-flight requests
    end

    -- unescape all parameters and recast booleans
    for k, v in pairs(self.params) do
        if ((v == 'true') or (v == 'false')) then
            self.params[k] = (v == 'true')
        else
            self.params[k] = package.loaded.util.unescape(tostring(v))
        end
    end

    if self.params.username and self.params.username ~= '' then
        self.params.username = self.params.username:lower()
        self.queried_user = package.loaded.Users:find({ username = self.params.username })
    end

    if self.session.username and self.session.username ~= '' then
        self.current_user = package.loaded.Users:find({ username = self.session.username })
    else
        self.session.username = ''
        self.current_user = nil
    end

    if self.params.matchtext then
        self.params.matchtext = '%' .. self.params.matchtext .. '%'
    end

end)

function app:handle_404()
    return errorResponse("Failed to find resource: " .. self.req.cmd_url, 404)
end

--[[
function app:handle_error(err, trace)
    local inspect = require('inspect')
    print(inspect(err))
    print(inspect(trace))
    local err_msg = exceptions.normalize_error(err)
    local user_info = exceptions.get_user_info(self.session)
    if config.sentry_dsn then
        local _, send_err = exceptions.rvn:captureException({{
            type = err_msg,
            value = err .. "\n\n" .. trace,
            trace_level = 2, -- Skip `handle_error`
        }}, { user = user_info })
        if send_err then
            ngx.log(ngx.ERR, send_err)
        end
    end
    return errorResponse("An unexpected error occured: " .. err_msg, 500)
end]]--

-- Enable the ability to have a maintenance mode
-- No routes are served, and a generic error is returned.
if config.maintenance_mode == 'true' then
    local msg = 'The Snap!Cloud is currently down for maintenance.'
    app:match('/*', function(self)
        return errorResponse(msg, 500)
    end)
    return app
end

-- The API is implemented in the api.lua file
require 'api'
require 'discourse'

-- We don't keep spam/exploit paths in the API
require 'spambots'

-- The community site is handled in the site.lua file
require 'site'

return app
