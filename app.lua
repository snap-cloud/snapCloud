-- Snap!Cloud
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
local lapis = require('lapis')
package.loaded.app = lapis.Application()
package.loaded.db = require('lapis.db')
package.loaded.validate = require('lapis.validate')
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

-- Cookie names, attributes and the __Host- session cookie migration.
-- Needs package.loaded.config; must load before the first request.
local cookies = require('lib.cookies')

package.loaded.disk = require('disk')
package.loaded.locale = require('locale')
package.loaded.validation = require("validation")

local app = package.loaded.app
local config = package.loaded.config

-- Snap!Cloud Utilities
local utils = require('lib.util')
-- Track exceptions, exposes raven and describe_error
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
local maintenance = require('maintenance')
package.loaded.maintenance = maintenance

-- Resolve the user this request belongs to, based on the session cookie.
--
-- Priority:
--   1. session.remember_token: the source of truth. Look up by token; if
--      it doesn't match a user the cookie is stale (token rotated by a
--      password change, "log out all sessions", etc.) and we treat the
--      request as logged-out.
--   2. JIT-migrate legacy cookies. A cookie minted before remember_token
--      existed will only carry session.username. We accept it ONLY if the
--      user's record has no remember_token yet — i.e. nobody has logged
--      in for this account since the column was added. We then issue a
--      token and pin it to the cookie.
--   3. If the user record DOES already have a remember_token, refuse the
--      tokenless cookie. Accepting it would defeat the whole point of
--      server-side invalidation: the legitimate owner has logged in
--      somewhere and rotated the token; the bare-username cookie is
--      either ours-but-stale or stolen, and either way it must lose.
local function resolve_current_user(self)
    local Users = package.loaded.Users
    local remember_token = self.session.remember_token

    if remember_token and remember_token ~= '' then
        return Users:find({ remember_token = remember_token })
    end

    local username = self.session.username
    if not username or username == '' then return nil end

    local user = Users:find({ username = username })
    if not user then return nil end

    if user.remember_token and user.remember_token ~= '' then
        return nil
    end

    -- Read-only maintenance: keep the user logged in, but don't write a token.
    if maintenance.mode then return user end

    self.session.remember_token = user:rotate_remember_token()
    return user
end

-- Track a "session" (a 4-hour window of activity) for the user. Called
-- after a request has been authenticated and current_user is set.
local function track_session_activity(self)
    -- Session counts are paused during read-only maintenance.
    if maintenance.mode then return end
    local should_count_session = false
    local last_session_at = self.current_user.last_session_at
    if not last_session_at then
        should_count_session = true
    elseif (date(true) - date(last_session_at)):spanhours() >= 4 then
        should_count_session = true
    end
    if should_count_session then
        self.current_user:update({
            last_session_at = package.loaded.db.format_date(),
            session_count = self.current_user.session_count + 1
        })
    end
end

-- Single entry point for "who is the user on this request?"
-- Mutates self.current_user and the session in place.
local function establish_session(self)
    self.current_user = resolve_current_user(self)
    if self.current_user then
        self.session.username = self.current_user.username
        self.session.last_access_at = date(true):fmt('${http}')
        track_session_activity(self)
    else
        self.session.username = ''
        self.session.remember_token = nil
        self.session.user_id = nil
    end
end

-- Lapis calls this once per cookie it writes. The policy (Secure, HttpOnly,
-- SameSite, Max-Age for "remember me", no Domain so __Host- works) and the
-- expiry of the legacy session cookie live in lib/cookies.lua.
app.cookie_attributes = function (self, name)
    return cookies.attributes(self, name)
end

-- CACHING UTILITIES
-- Custom caching to take in account current locale
local lapis_cached = require('lapis.cache').cached
package.loaded.cached = function (func, options)
    if config._name == 'development' then
        return func
    end

    local options = options or {}
    local cache_key = function (path, params, request)
        local key = path
        local param_keys = {}
        for k, _ in pairs(params) do table.insert(param_keys, k) end
        table.sort(param_keys)
        for _, v in ipairs(param_keys) do
            key = key .. '#' .. v .. '=' .. tostring(params[v])
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
    -- Temporarily disable IP bans because of too many false positives
    --[[
    local ip_entry = package.loaded.BannedIPs:find(ngx.var.remote_addr)
    if (ip_entry and ip_entry.offense_count > 2) then
        self:write(
            errorResponse(self, 'Your IP has been banned from the system', 403)
        )
        return
    end
    ]]--

    -- Must run before anything reads self.session: lapis decodes the session
    -- cookie on first access and keeps the result, so a stale twin of the
    -- cookie has to be dealt with first. See lib/cookies.lua.
    cookies.drop_encoded_twins(self)

    -- Make locale available to all routes and templates
    self.locale = package.loaded.locale
    self.locale.language = self.session.locale or 'en'

    -- Make our utilities (escape_html, js_string...) available to templates
    self.util = utils

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

    -- Maintenance (see maintenance.lua). After the CORS headers, so the Snap!
    -- editor can read the message. The DB is read-only in maintenance; refusing
    -- writes here too gives a clear message and stops disk-only writes.
    if maintenance.mode then
        self.maintenance_mode = maintenance.mode
        self.maintenance_message = maintenance.message
        local method = ngx.req.get_method()
        if maintenance.mode == 'down' or
                (method ~= 'GET' and method ~= 'HEAD') then
            self:write(maintenance.response(self))
            return
        end
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
    elseif self.params.user_id and self.params.user_id ~= '' then
        self.queried_user =
            package.loaded.Users:find({ id = self.params.user_id })
        if self.queried_user then
            self.params.username = self.queried_user.username
        end
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

    -- Users still carrying the pre-__Host- session cookie are moved over
    -- (and the old cookie expired) before the session is used.
    cookies.migrate_legacy_session(self)

    establish_session(self)

    if self.params.matchtext then
        self.params.matchtext = '%' .. tostring(self.params.matchtext) .. '%'
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
    -- Errors raised with a table (yield_error({...}) outside capture_errors)
    -- would otherwise crash the string concatenations below.
    err = tostring(err)
    trace = tostring(trace)
    -- The database is read-only during maintenance, so a route that tries to
    -- write ends up here. Show the maintenance message, not a 500.
    if maintenance.is_read_only_db_error(err) then
        return maintenance.response(self)
    end

    -- Lapis raises this error from `respond_to` when a request uses an HTTP
    -- method the route does not handle. Return a 405 instead of a 500.
    if type(err) == 'string' and err:match("don't know how to respond to") then
        return errorResponse(
            self,
            'The server received an unexpected request. ' ..
            'Please refresh the page and try again.',
            405
        )
    end

    local ok, report = pcall(exceptions.describe_error, err, trace)
    if not ok then
        report = { exception = { type = 'LuaError', value = err } }
    end
    local function report_to_sentry()
        if not config.sentry_dsn or report.silent then return end
        local _, send_err = exceptions.rvn:captureException(
            { report.exception }, {
                user = exceptions.get_user_info(self.session),
                culprit = report.culprit,
                extra = report.extra,
                fingerprint = report.fingerprint,
                transaction = exceptions.transaction_name(self.original_request),
            })
        if send_err then
            ngx.log(ngx.ERR, send_err)
        end
    end

    -- Capacity problems and unsupported requests get their own status.
    if report.status then
        report_to_sentry()
        return errorResponse(self, report.message, report.status)
    end

    if config._name == 'development' then
        debug_print(err, trace)
        local accept = self.req.headers.accept or ''
        if type(accept) == 'table' then accept = table.concat(accept, ',') end
        if accept:match('text/html') then
            -- Keep the traceback readable: monospace, left-aligned, with its
            -- indentation intact. Escaped first, since err can echo request
            -- data; html_message_page prints contents as-is.
            return html_message_page(self, '500 Error',
                '<pre style="text-align: left; width: 80ch">' ..
                utils.escape_html(err .. '\n' .. trace) .. '</pre>', 500)
        end
        -- API clients get the plain text in the JSON error body.
        return errorResponse(self, err .. '\n' .. trace, 500)
    end


    report_to_sentry()
    return errorResponse(self,
        'An unexpected error occurred: ' .. report.exception.value, 500)
end

-- The API for the Snap! editor is implemented in the api.lua file
require 'api'
require 'discourse'

-- We don't keep spam/exploit paths in the API
-- Disabled for now to prevent false positives
-- require 'spambots'

-- The community site is handled in the site.lua file
require 'site'

return app
