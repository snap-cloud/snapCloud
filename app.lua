-- Snap Cloud
-- ==========
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa
--
-- Copyright (C) 2018 by Bernat Romagosa
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
package.loaded.json_params = package.loaded.app_helpers.json_params
package.loaded.yield_error = package.loaded.app_helpers.yield_error
package.loaded.validate = require 'lapis.validate'
package.loaded.Model = require('lapis.db.model').Model
package.loaded.util = require('lapis.util')
package.loaded.respond_to = require('lapis.application').respond_to
package.loaded.cached = require('lapis.cache').cached
package.loaded.resty_sha512 = require "resty.sha512"
package.loaded.resty_string = require "resty.string"
package.loaded.resty_random = require "resty.random"
package.loaded.config = require("lapis.config").get()
package.loaded.crypto = require('crypto')

local app = package.loaded.app

-- Store whitelisted domains
local domain_allowed = require('cors')

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

require 'responses'
local date = require("date")

-- Make cookies persistent
app.cookie_attributes = function(self)
    local expires = date(true):adddays(365):fmt("${http}")
    return "Expires=" .. expires .. "; Path=/; HttpOnly; Secure"
end

-- Database abstractions
local function update_timestamps(object)
    -- replace all timestamps with an ISO8061 formatted string.
    -- Postgres dates don't include the "T" time seperator
    -- They are missing the minutes value on timezones, which JS needs
    -- FROM: 2017-09-01 08:33:50.127-07 TO: 2017-09-01T08:33:50-07:00
    local timestamp_columns = {}
    timestamp_columns['created'] = true
    timestamp_columns['updated'] = true
    timestamp_columns['lastupdated'] = true
    timestamp_columns['lastshared'] = true
    timestamp_columns['firstshared'] = true
    for column, value in pairs(object) do
        -- would be nice to do column:find('_at$')
        if timestamp_columns[column] then
            iso_8601_date = date(value):fmt('${iso}%z'):gsub('(%d%d$)', ':%1')
            object[column] = iso_8601_date
        end
    end
    return object
end

-- Have SELECT statements return timestamps from the DB in IS08601
local original_query = package.loaded.db.query
function package.loaded.db.query(query, ...)
    local result = original_query(query, ...)
    for i, obj in ipairs(result) do
        result[i] = update_timestamps(obj)
    end
    return result
end

package.loaded.Users = package.loaded.Model:extend('users', {
    primary_key = { 'username' }
})

package.loaded.Projects = package.loaded.Model:extend('projects', {
    primary_key = { 'username', 'projectname' }
})

package.loaded.Tokens = package.loaded.Model:extend('tokens', {
    primary_key = { 'value' }
})

-- Remove the protocol and port from a URL
function domain_name(url)
    if not url then
        return
    end
    return url:gsub('https*://', ''):gsub(':%d+$', '')
end

-- Before filter
app:before_filter(function (self)
    -- unescape all parameters
    for k, v in pairs(self.params) do
        self.params[k] = package.loaded.util.unescape(v)
    end

    if self.params.username then
        self.params.username = self.params.username:lower()
    end

    if not self.session.username then
        self.session.username = ''
    end

    -- Set Access Control header
    local domain = domain_name(self.req.headers.origin)
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
    print(err)
    print(trace)
    return errorResponse(err, 500)
end

-- The API is implemented in the api.lua file

require 'api'
require 'discourse'

return app
