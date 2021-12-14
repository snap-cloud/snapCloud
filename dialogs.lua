-- Dialog HTML strings
-- ===================
--
-- Escaped HTML strings for all dialogs.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2021 by Bernat Romagosa and Michael Ball
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

local escape_html = function (html)
    local escaped = html
    local map = {}

    map['&'] = '&amp;'
    map['<'] = '&lt;'
    map['>'] = '&gt;'
    map['"'] = '&quot;'
    map["'"] = '&#039;'

    for k, v in pairs(map) do
        escaped = escaped:gsub(k, v)
    end
    return escaped
end

local compact = function (text)
    return text:gsub('\n', '')
end

package.loaded.dialogs = {
    delete_project = compact([[
Are you sure you want to delete this project?<br>
<i class="warning fa fa-exclamation-triangle"></i>
 WARNING! This action cannot be undone! 
<i class="warning fa fa-exclamation-triangle"></i>
]])
}
