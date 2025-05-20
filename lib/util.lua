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

local function cache_buster ()
    -- if config._name == "development" then
    --   return os.time()
    -- end
    local cache = ngx.shared.session_cache

    -- Check if cache exists
    if not cache then
      ngx.log(ngx.ERR, "Shared dict 'session_cache' not found")
      return nil
    else
      debug_print("Cache found")
      debug_print(cache)
    end

    local value = cache:get("my_key")
      debug_print(value)
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
  domain_name = domain_name,
  escape_html = escape_html,
  visualize_whitespace_html = visualize_whitespace_html,
  group_by_type = group_by_type,
  cache_buster = cache_buster,
}
