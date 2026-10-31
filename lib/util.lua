-- Snap!Cloud Utilities
-- =====================
--
-- A cloud backend for Snap!
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2023 by Bernat Romagosa and Michael Ball
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

local os = require('os')
local config = package.loaded.config

local function capitalize(str)
    return str:gsub("^%l", string.upper)
end

-- Absolute URL for links that leave the site, such as password reset and
-- email verification links. self:build_url() takes its host from the
-- request's Host header, which an attacker can set to their own domain and
-- have the victim emailed a link pointing there. This uses configuration only.
local function canonical_url(path)
    local base = config.cloud_url
    if not base or base == '' then
        if config._name == 'production' or config._name == 'staging' then
            base = 'https://' .. config.hostname
        else
            base = 'http://localhost:' .. tostring(config.port)
        end
    end
    return (base:gsub('/+$', '')) .. path
end

-- Remove the protocol and port from a URL
local function domain_name(url)
  if not url then
      return
  end
  return url:gsub('https*://', ''):gsub(':%d+$', '')
end

local function escape_html(text)
  if text == nil then return end

  text = tostring(text)
  local map = {
      ["&"] = "&amp;",
      ["<"] = "&lt;",
      [">"] = "&gt;",
      ['"'] = "&quot;",
      ["'"] = "&#039;"
  }

  return (text:gsub("[&<>\'\"]", function(m)
      return map[m]
  end))
end

-- Turns plain text, such as a message typed into a textarea, into HTML:
-- escaped, with newlines as <br>.
local function text_to_html(text)
  if text == nil then return '' end
  return (escape_html(text):gsub('\r?\n', '<br>'))
end

-- Turns a value into a JavaScript string literal, quotes included, for use
-- in templates. Quotes, backslashes, <, >, & and control characters are
-- written as \u escapes, so the result can't end the string, a <script> tag
-- or an HTML attribute. That makes it safe both in <script> blocks and in
-- attributes like onclick="...". Always output it raw:
--   cloud.post('/users/' + <%- util.js_string(item.username) %> + '/verify')
local function js_string(value)
  if value == nil then return "''" end
  local escaped = tostring(value):gsub('[%c\\\'"<>&]', function (char)
    return string.format('\\u%04x', char:byte())
  end)
  return "'" .. escaped .. "'"
end

local function visualize_whitespace_html(str)
    if not str then
        return "<code>[nil]</code>"
    end

    if str == "" then
        return "<code>[empty]</code>"
    end

    local map = {
        [" "] = "·",
        ["\t"] = "→",
        ["\n"] = "↵",
        ["\r"] = "⏎"
    }

    return escape_html(str):gsub("[\t\n\r ]", function(m)
        return '<code>' .. map[m] .. '</code>'
    end)
end

local function group_by_type(items)
  local result = {}
  for _, item in ipairs(items) do
    if not result[item.type] then
      result[item.type] = {}
    end
    table.insert(result[item.type], item)
  end
  return result
end

-- Lock a page out of any cross-origin frame. Use on auth-bearing pages
-- (login, password change, reset, etc.) so they cannot be clickjacked.
-- Sets both the legacy X-Frame-Options header and the modern
-- frame-ancestors CSP directive — frame-ancestors is what current
-- browsers honour, X-Frame-Options is the belt-and-suspenders fallback.
local function set_no_frame_headers(self)
    self.res.headers['X-Frame-Options'] = 'DENY'
    self.res.headers['Content-Security-Policy'] = "frame-ancestors 'none'"
end

local function cache_buster ()
    if config._name == "development" then
      return os.time()
    end
    local cache = ngx.shared.session_cache
    if cache:get('cache_buster') then
      return cache:get('cache_buster')
    end
    local cache_buster_value = os.time()
    if config.release_sha then
      cache_buster_value = config.release_sha
    end
    cache:set('cache_buster', cache_buster_value)
    return cache_buster_value
end


return {
  capitalize = capitalize,
  canonical_url = canonical_url,
  domain_name = domain_name,
  escape_html = escape_html,
  text_to_html = text_to_html,
  js_string = js_string,
  visualize_whitespace_html = visualize_whitespace_html,
  group_by_type = group_by_type,
  cache_buster = cache_buster,
  set_no_frame_headers = set_no_frame_headers,
}
