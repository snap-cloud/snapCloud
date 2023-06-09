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
-- Snap Cloud is free software: you can gtfstribute it and/or modify
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
local lapis = require('lapis')
package.loaded.app = lapis.Application()
package.loaded.db = require('lapis.db')
package.loaded.validate = require('lapis.validate')
package.loaded.Model = require('lapis.db.model').Model
package.loaded.util = require('lapis.util')
package.loaded.resty_sha512 = require('resty.sha512')
package.loaded.resty_string = require('resty.string')
package.loaded.resty_random = require('resty.random')
package.loaded.config = require('lapis.config').get()
package.loaded.cjson = require('cjson')
package.loaded.app_helpers = require('lapis.application')
package.loaded.json_params = package.loaded.app_helpers.json_params
package.loaded.yield_error = package.loaded.app_helpers.yield_error
package.loaded.respond_to = package.loaded.app_helpers.respond_to
package.loaded.html = require('lapis.html')
local date = require('date')

package.loaded.disk = require('disk')
package.loaded.locale = require('locale')

local app = package.loaded.app
local config = package.loaded.config

-- Snap!Cloud Utilities
local utils = require('lib.util')
-- Track exceptions, exposes raven, rollbar, and normalize_error
local exceptions = require('lib.exceptions')
local domain_allowed = require('cors')

-- Snap!Cloud overrides
-- Provides debug_print, string.from_sql_date
require('lib.global')

-- wrap the lapis capture errors to provide our own custom error handling
-- just do: yield_error({msg = 'oh no', status = 401})
local lapis_capture_errors = package.loaded.app_helpers.capture_errors
package.loaded.capture_errors = function(fn)
    return lapis_capture_errors({
        on_error = function(self)
            local error = self.errors[1]
            if type(error) == 'table' then
                return errorResponse(self, error.msg, error.status)
            else
                return errorResponse(self, error, 400)
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
    return "Expires=" .. expires .. "; Path=/; HttpOnly; SameSite=" ..
                sameSite .. ";" .. secure
end

-- CACHING UTILITIES
-- Custom caching to take in account current locale
local lapis_cached = require('lapis.cache').cached
package.loaded.cached = function (func, options)
    local options = options or {}
    local cache_key = function (path, params, request)
        local key = path
        local param_keys = {}
        for k, _ in pairs(params) do table.insert(param_keys, k) end
        table.sort(param_keys)
        for _, v in ipairs(param_keys) do
            key = key .. '#' .. v .. '=' .. params[v]
        end
        return key .. '@' .. (request.session.locale or 'en') ..
            '~' .. (request.session.username)
    end

    local function no_cache (request) return request.params.no_cache ~= true end

    return lapis_cached({
        dict_name = 'page_cache', -- default dictionary, unchanged
        exptime = options.exptime or 30,
        cache_key = cache_key,
        when = options.when or no_cache,
        func
    })
end

-- cache for SQL queries so we're not constantly bombarding the DB
package.loaded.cached_query = function (key_table, category, model, on_miss)
    local cache = ngx.shared.query_cache

    local sorted_keys = {}
    for _, v in pairs(key_table) do table.insert(sorted_keys, tostring(v)) end
    table.sort(sorted_keys)

    local key = ''
    for _, v in ipairs(sorted_keys) do key = key .. '#' .. v end

    local contents = cache:get(key)
    if contents == nil then
        -- run the function that was passed for when there's a cache miss
        contents = on_miss()
        cache:set(key, package.loaded.util.to_json(contents))
        if category then
            ngx.shared.query_cache_categories:set(category, key)
        end
    else
        contents = package.loaded.util.from_json(contents)
        if model then
            for _, item in ipairs(contents) do
                setmetatable(item, model.__index)
            end
        end
    end
    return contents
end

package.loaded.uncache_category = function (category)
    local query = ngx.shared.query_cache_categories:get(category)
    if query then ngx.shared.query_cache:delete(query) end
end

-- Before filter
app:before_filter(function (self)
    local ip_entry = package.loaded.BannedIPs:find(ngx.var.remote_addr)
    if (ip_entry and ip_entry.offense_count > 2) then
        self:write(
            errorResponse(self, 'Your IP has been banned from the system', 403)
        )
        return
    end

    -- Make locale available to all routes and templates
    self.locale = package.loaded.locale
    self.locale.language = self.session.locale or 'en'

    self.req.source =
        (self.req.headers['content-type'] and
            self.req.headers['content-type']:find('json')) and 'snap' or 'site'

    -- Set Access Control header
    local domain = utils.domain_name(self.req.headers.origin)
    if self.req.headers.origin and domain_allowed[domain] then
        self.res.headers['Access-Control-Allow-Origin'] =
            self.req.headers.origin
        self.res.headers['Access-Control-Allow-Credentials'] = 'true'
        self.res.headers['Vary'] = 'Origin'
    end

    if ngx.req.get_method() == 'OPTIONS' then
        self.res.headers['access-control-allow-headers'] = 'Content-Type'
        self.res.headers['access-control-allow-methods'] =
            'GET, POST, DELETE, OPTIONS'
        self:write(rawResponse('preflight processed'))
        return
    end

    if ngx.req.get_method() == 'POST' then
        -- read body params for all POST requests
        ngx.req.read_body()
        local body = ngx.req.get_body_data()
        -- try to decode it, if it fails it's not proper JSON
        if pcall(function () package.loaded.util.from_json(body) end) then
            local post_params = package.loaded.util.from_json(body)
            for k, v in pairs(post_params) do
                self.params[k] = v
            end
        else
            self.params.body = body
        end
    end

    if self.params.username and self.params.username ~= '' then
        self.params.username =
            package.loaded.util.unescape(
                tostring(self.params.username)):lower()
        self.queried_user =
            package.loaded.Users:find({ username = self.params.username })
    end

    -- unescape all parameters and JSON-decode them
    for k, v in pairs(self.params) do
        if type(v) == 'string' then
            -- leave strings alone
            self.params[k] = package.loaded.util.unescape(v)
        elseif pcall(function () package.loaded.util.from_json(v) end) then
            -- try to decode it, if it fails it's not proper JSON
            self.params[k] =
                package.loaded.util.from_json(
                    package.loaded.util.unescape(v)
                )
        end
    end

    if self.session.username and self.session.username ~= '' then
        self.current_user =
            package.loaded.Users:find({ username = self.session.username })
    else
        self.session.username = ''
        self.current_user = nil
    end

    if self.params.matchtext then
        self.params.matchtext = '%' .. self.params.matchtext .. '%'
    end

end)

function app:default_route()
    ngx.log(ngx.NOTICE, "User hit unknown path " .. self.req.parsed_url.path)

    -- handle an open redirect vuln so nas not to redirect to different domains
    self.req.parsed_url.path = string.gsub(self.req.parsed_url.path, '//', '/')

    -- call the original implementaiton to preserve the functionality it provides
    return lapis.Application.default_route(self)
end

function app:handle_404()
    return errorResponse(self, 'Failed to find resource: ' .. self.req.cmd_url, 404)
end

function app:handle_error(err, trace)
    if config._name == 'development' then
        debug_print(err, trace)
        local msg = '<pre style="text-align: left; width: 80ch">'
            .. err .. '<br>' .. trace .. '</pre>'
        return errorResponse(self, msg, 500)
    end

    local err_msg = exceptions.normalize_error(err)
    local user_info = exceptions.get_user_info(self.session)
    if config.sentry_dsn then
        local _, send_err = exceptions.rvn:captureException({{
            type = err_msg,
            value = err .. "\n\n" .. trace,
            trace_level = 2, -- skip `handle_error`
        }}, { user = user_info })
        if send_err then
            ngx.log(ngx.ERR, send_err)
        end
    end
    return errorResponse(self, "An unexpected error occured: " .. err_msg, 500)
end

-- Enable the ability to have a maintenance mode
-- No routes are served, and a generic error is returned.
if config.maintenance_mode == 'true' then
    local msg = 'The Snap!Cloud is currently down for maintenance.'
    app:match('/*', function(self)
        return errorResponse(self, msg, 500)
    end)
    return app
end

-- The API for the Snap! editor is implemented in the api.lua file
require 'api'
require 'discourse'

-- We don't keep spam/exploit paths in the API
require 'spambots'

-- The community site is handled in the site.lua file
require 'site'

return app
