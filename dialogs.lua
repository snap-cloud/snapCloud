-- Dialog body contents
-- ====================
--
-- Generates HTML contents for all dialog boxes using etlua.
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

local etlua = require('etlua')

local compact = function (text)
    -- remove newlines, and escape single quotes
    return text:gsub('\n', ''):gsub("'", '&#039;')
end

package.loaded.dialog = function (filename, params)
    local file = io.open('views/dialogs/' .. filename .. '.etlua', 'r')
    if file then
        local contents = file:read('*all')
        file:close()
        local template = etlua.compile(contents)
        return compact(template(params))
    else
        return '<h1>Dialog render error</h1><span>template ' ..
                    filename .. ' not found under views/dialogs/'
    end
end
