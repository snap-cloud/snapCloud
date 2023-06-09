-- Snap!Cloud Global Overrides
-- ===========================
--
-- Use this file to override lua defaults
-- or provide functions that are intended to be used anywhere.
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
-- along with this program. If not, see <http://www.gnu.org/licenses/>.

-- Print tables as JSON by default. Lets us use tables in etlua templates
-- without having to convert them to JSON explicitly, which is nice.
local old_tostring = tostring
tostring = function (obj)
    if (type(obj) == 'table') then
        return package.loaded.util.to_json(obj)
    else
        return old_tostring(obj)
    end
end

debug_print = function (title, string)
  print('\n\n----------\n' .. (string and title or 'DEBUG') .. '\n' ..
      require('inspect').inspect(string or title) ..
      '\n----------\n'
  )
end

local date = require("date")
string.from_sql_date = function (sql_date)
    -- Formats an SQL date into (i.e.) November 21, 2021
    local month_names = { 'january', 'february', 'march', 'april', 'may',
        'june', 'july', 'august', 'september', 'october', 'november', 'december'
    }
    if (sql_date == nil) then return 'never' end
    local actual_date = date(sql_date)
    return package.loaded.locale.get(
        'date',
        actual_date:getday(),
        package.loaded.locale.get(month_names[actual_date:getmonth()]),
        actual_date:getyear()
    )
end
