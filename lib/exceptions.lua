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
local config = package.loaded.config
local util = package.loaded.util

-- Setup seed for raven to generate event ids.
math.randomseed(os.time())

local rvn = nil
if config.sentry_dsn then
  rvn = raven.new({
    sender = require("raven.senders.luasocket").new { dsn = config.sentry_dsn },
    environment = config._name,
    release = config.release_sha
  })
end

local exceptions = {
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

raven.get_release = function()
  return config.release_sha
end

-- Redaction for everything that leaves the server for Sentry.
-- Headers: the session cookie and any credentials.
-- Params: anything that looks like a secret. Values are matched by key name
-- only, so a password typed into a field with another name would still leak;
-- keep the list generous rather than clever.
local FILTERED = '[Filtered]'
local sensitive_headers = {
  cookie = true, authorization = true, ['proxy-authorization'] = true,
  ['x-csrf-token'] = true,
}
local sensitive_key_needles =
  { 'password', 'passwd', 'token', 'secret', 'cookie', 'session', 'api_key' }

local function is_sensitive_key(key)
  key = tostring(key):lower()
  for _, needle in ipairs(sensitive_key_needles) do
    if key:find(needle, 1, true) then return true end
  end
  return false
end

-- Returns a copy of `value` with sensitive keys replaced, bounded in depth
-- and width so a hostile body cannot turn error reporting into a CPU sink.
local function scrub(value, depth)
  depth = depth or 0
  if type(value) ~= 'table' then return value end
  if depth > 4 then return '[Truncated]' end
  local out, count = {}, 0
  for k, v in pairs(value) do
    count = count + 1
    if count > 100 then out['...'] = '[Truncated]' break end
    if is_sensitive_key(k) then
      out[k] = FILTERED
    else
      out[k] = scrub(v, depth + 1)
    end
  end
  return out
end

local function scrub_headers(headers)
  local out = {}
  for name, value in pairs(headers or {}) do
    if sensitive_headers[tostring(name):lower()] then
      out[name] = FILTERED
    else
      out[name] = value
    end
  end
  return out
end

-- Send data about each request to sentry.
-- This was adapted from rollbar.lua. It used to ship the raw headers, the
-- raw body and the whole config table (database and mail passwords, the
-- session secret) with every exception. Now only redacted request data and
-- a few non-secret environment facts go out.
raven.get_request_data = function()
  local url = ngx.var.scheme..'://'..ngx.var.host..ngx.var.request_uri
  local method = ngx.req.get_method()
  local request = {
    url = url,
    method = method,
    headers = scrub_headers(ngx.req.get_headers()),
    query_string = ngx.var.args,
    env = {
      LAPIS_ENVIRONMENT = config._name,
      RELEASE_SHA = config.release_sha,
      REMOTE_ADDR = ngx.var.remote_addr,
    }
  }
  if method == 'GET' then
    request.GET = scrub(ngx.req.get_uri_args())
  elseif method == 'POST' then
    ngx.req.read_body()
    local args, err = ngx.req.get_post_args()
    local body_data = ngx.req.get_body_data()
    if err then
      request.data = 'ERROR READING POST ARGS'
    else
      -- Parse post as JSON if possible.
      local success, result = pcall(function() return body_data and util.from_json(body_data) end)
      if success and type(result) == 'table' then
        request.data = scrub(result)
      elseif success and result ~= nil then
        -- a non-object body (the raw password sent to /login, for instance)
        request.data = FILTERED
      else
        request.data = scrub(args)
      end
    end
  end
  return request
end

-- Lapis hands `handle_error` two strings: `err`, which carries every
-- `file:line:` prefix added on the way up plus the traceback of the coroutine
-- that failed, and `trace`, the stack of the dispatcher itself.
local STRIP_PREFIXES = {
  '^%./', '^lua_modules/share/lua/[%d%.]+/', '^.-/share/lua/[%d%.]+/'
}

local function is_app_frame(_, raw_path)
  return raw_path:find('^%./') ~= nil and raw_path:find('^%./lua_modules/') == nil
end

-- Returns an exception table for Sentry, the innermost application frame as
-- culprit, and extra data (the failed query, Postgres detail, raw traceback).
exceptions.describe_error = function(err, trace)
  err = tostring(err)
  local message, traceback = err:match('^(.-)\n(stack traceback:.*)$')
  message = message or err
  local prefix = '^%S-%.lua:%d+:%s*'
  while message:match(prefix) do
    message = message:gsub(prefix, '', 1)
  end

  local exception, extra = {}, { traceback = traceback or trace }
  local pg_error = message:match('\n(ERROR:.*)$')
  if pg_error then
    exception.type = 'PostgresError'
    local value = pg_error:match('^ERROR:%s*([^\n]*)')
    extra.position = value:match('%((%d+)%)$')
    exception.value = (value:gsub('%s*%(%d+%)$', ''))
    extra.detail = pg_error:match('\n(.*)$')
    extra.query = message:sub(1, #message - #pg_error - 1)
  else
    exception.type = 'LuaError'
    exception.value =
      (message:match('^[^\n]*'):gsub('%f[%w]%d+%f[%W]', '[NUMBER]'))
  end

  exception.stacktrace = raven.parse_traceback(
    traceback or trace, { strip = STRIP_PREFIXES, in_app = is_app_frame })
  local culprit
  for _, frame in ipairs(exception.stacktrace.frames) do
    if frame.in_app then
      culprit = frame.filename .. ':' .. frame.lineno ..
        ' in ' .. tostring(frame['function'])
    end
  end
  return exception, culprit, extra
end

-- The Lapis pattern that matched, e.g. "POST /(api/v1/)projects/:username/:projectname".
exceptions.transaction_name = function(request)
  local pattern = request and request.route_pattern
  if type(pattern) ~= 'string' then return nil end
  return request.req.method .. ' ' .. pattern
end

return exceptions
