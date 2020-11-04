-- Exception Tracking for Snap!Cloud
-- ==================================
-- Utilies for error logging and debugging.
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

-- look for a local package in the right spot.
package.path = [[./lib/raven-lua/?.lua;./lib/raven-lua/?/init.lua;]] .. package.path

local raven = require("raven")
local math = require("math")
local rollbar = require("resty.rollbar")
local config = package.loaded.config

-- Setup seed for raven to generate event ids.
math.randomseed(os.time())

rollbar.set_token(config.rollbar_token)
rollbar.set_environment(config._name)

local rvn = raven.new({
  sender = require("raven.senders.luasocket").new { dsn = config.sentry_dsn },
  environment = config._name,
  release = config.release_sha
})

local exceptions = {
  rollbar = rollbar,
  raven = raven,
  rvn = rvn
}

--- Return the current user id and username for tracking with the exception.
exceptions.get_user_info = function(session)
  local current_user = nil
  if session.username then
    current_user = package.loaded.Users:find({ username = session.username })
  end

  if current_user then
    return current_user:logging_params()
  end
end

-- Used by Sentry to identify the server.
-- If we ever deploy multiple servers, we should adjust this function.
raven.get_server_name = function()
  return 'Snap!Cloud - ' .. ngx.var.host
end

-- Send data about each request to sentry.
-- This was adapted from rollbar.lua
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

-- This function is extracted from lapis-exceptions by @leafo
-- https://github.com/leafo/lapis-exceptions/blob/master/lapis/exceptions/models/exception_types.lua#L6
local grammar = nil
local make_grammar
make_grammar = function()
local P, R, Cs
do
  local _obj_0 = require("lpeg")
  P, R, Cs = _obj_0.P, _obj_0.R, _obj_0.Cs
end
local make_str
make_str = function(delim)
  local d = P(delim)
  return d * (P([[\]]) * d + (P(1) - d)) ^ 0 * d
end
local rep
rep = function(name)
  return function()
    return "[" .. tostring(name) .. "]"
  end
end
local num = R("09") ^ 1 * (P(".") * R("09") ^ 1) ^ -1
local str = make_str([[']]) + make_str([["]])
local line_no = P(":") * num * P(":")
local string = P("'") * (P(1) - P("'")) * P("'")
grammar = Cs((line_no + (num / rep("NUMBER")) + (str / rep("STRING")) + P(1)) ^ 0)
end

-- Clean up exceptions to not include user-specific strings.
-- Adapted from lapis-exceptions to also trim the path to the calling file.
exceptions.normalize_error = function(str)
    if not (grammar) then
        make_grammar()
    end
    local first = str:match("^[^\n]+")
    local result = grammar:match(first) or first
    -- Additionally, trim the fat of standard paths, everything before *.lua:lineno
    local _, last = string.find(result, '[%w]+.lua:%d+:%s*')
    return string.sub(result, last, -1)
end

return exceptions
