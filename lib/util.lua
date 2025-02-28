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

return {
  capitalize = capitalize,
  domain_name = domain_name,
  escape_html = escape_html,
}
