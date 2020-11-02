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

-- _G Write guard spam hack. TODO: clean this up.
rawset(_G, 'lfs', false)
rawset(_G, 'lpeg', false)
rawset(_G, 'socket', false)
rawset(_G, 'ltn12', false)

rawset(_G, 'create_redirect_url', false)
rawset(_G, 'build_payload', false)
rawset(_G, 'extract_payload', false)
rawset(_G, 'tbl', false)
rawset(_G, 'APIController', false)
rawset(_G, 'CollectionController', false)
rawset(_G, 'ProjectController', false)
rawset(_G, 'UserController', false)
rawset(_G, 'random_password', false)
rawset(_G, 'secure_token', false)
rawset(_G, 'secure_salt', false)
rawset(_G, 'jsonResponse', false)
rawset(_G, 'xmlResponse', false)
rawset(_G, 'okResponse', false)
rawset(_G, 'errorResponse', false)
rawset(_G, 'htmlPage', false)
rawset(_G, 'cors_options', false)
rawset(_G, 'rawResponse', false)
rawset(_G, 'TIMEOUT', false)
rawset(_G, 'bad_func', false)
rawset(_G, 'mail_bodies', false)
rawset(_G, 'mail_subjects', false)
rawset(_G, 'send_mail', false)
rawset(_G, 'err', false)
rawset(_G, 'assert_all', false)
rawset(_G, 'assert_logged_in', false)
rawset(_G, 'assert_role', false)
rawset(_G, 'assert_has_one_of_roles', false)
rawset(_G, 'assert_admin', false)
rawset(_G, 'assert_can_set_role', false)
rawset(_G, 'users_match', false)
rawset(_G, 'assert_users_match', false)
rawset(_G, 'assert_user_exists', false)
rawset(_G, 'assert_users_have_email', false)
rawset(_G, 'assert_project_exists', false)
rawset(_G, 'check_token', false)
rawset(_G, 'create_token', false)
rawset(_G, 'can_edit_collection', false)
rawset(_G, 'assert_collection_exists', false)
rawset(_G, 'assert_can_view_collection', false)
rawset(_G, 'assert_can_add_project_to_collection', false)
rawset(_G, 'assert_can_remove_project_from_collection', false)
rawset(_G, 'assert_project_not_in_collection', false)
rawset(_G, 'course_name_filter', false)
rawset(_G, 'hash_password', false)
rawset(_G, 'create_signature', false)

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
package.loaded.rollbar = require('resty.rollbar')
package.loaded.disk = require('disk')

local app = package.loaded.app
local config = package.loaded.config

-- Track exceptions
local helpers = require('helpers')
local rollbar = package.loaded.rollbar
rollbar.set_token(config.rollbar_token)
rollbar.set_environment(config._name)

-- Store whitelisted domains
local domain_allowed = require('cors')

-- Utility functions
local date = require("date")

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
    local secure = config._name ~= 'development' and " Secure" or ""
    return "Expires=" .. expires .. "; Path=/; HttpOnly; SameSite=None;" .. secure
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

    -- unescape all parameters
    for k, v in pairs(self.params) do
        self.params[k] = package.loaded.util.unescape(tostring(v))
    end

    if self.params.username and self.params.username ~= '' then
        self.params.username = self.params.username:lower()
        self.queried_user = package.loaded.Users:find({ username = self.params.username })
    end

    if self.session.username then
        self.current_user = package.loaded.Users:find({ username = self.session.username })
    else
        self.session.username = ''
        self.current_user = nil
    end

    if self.params.matchtext then
        self.params.matchtext = '%' .. self.params.matchtext .. '%'
    end
end)

-- requires raven to be at ./raven/*
local raven = require "raven"

-- This module only takes care of the index endpoint
app:get('/', function(self)
    return { redirect_to = self:build_url('site/') }
end)

function app:handle_404()
    return errorResponse("Failed to find resource: " .. self.req.cmd_url, 404)
end

local rvn = raven.new({
    sender = require("raven.senders.luasocket").new { dsn = config.sentry_dsn },
    environment = config._name,
})
raven.get_server_name = function()
    return 'Snap!Cloud'
end
raven.get_request_data = function()
    local url = ngx.var.scheme..'://'..ngx.var.host..ngx.var.request_uri
    local method = ngx.req.get_method()
    local request = {
      url = url,
      method = method,
      headers = ngx.req.get_headers(),
      query_string = ngx.var.args,
      env = config
    }
    if method == 'GET' then
      request.GET = ngx.req.get_uri_args()
    elseif method == 'POST' then
      ngx.req.read_body()
      local args, err = ngx.req.get_post_args()
      if err then
        request.data = 'ERROR READING POST ARGS'
      else
        request.data = args
      end
    end
    return request
end
-- Setup seed for raven to generate event ids.
local math = require('math')
math.randomseed(os.time())

function app:handle_error(err, trace)
    -- self.current_user is not available here.
    local current_user = nil
    local user_params = { id = 0, username = "logged-out" }
    if self.session.username then
        current_user = package.loaded.Users:find({ username = self.session.username })
    end

    if current_user then
        user_params = current_user:rollbar_params()
    end

    local err_msg = helpers.normalize_error(err)

    local _, send_err = rvn:captureException({{
        type = err_msg,
        module = string.sub(err_msg, 1, string.find(err_msg, " ")),
        value = err,
        trace_level = 3, -- Skip `handle_error`
    }}, {
        user = user_params
    })
    if send_err then
        ngx.say(ngx.ERROR, send_err)
    end
    rollbar.set_person(user_params)
    rollbar.set_custom_trace(err .. "\n\n" .. trace)
    rollbar.report(rollbar.ERR, err_msg)
    return errorResponse("An unexpected error occured: " .. err_msg, 500)
end

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

return app
