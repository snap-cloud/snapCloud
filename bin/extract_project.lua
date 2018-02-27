-- Extraction utility
-- ==================
--
-- This utility helps migrate records from the old cloud into the new one.
-- Not meant to be used from Lapis but as a command-line utility.
--
-- written by Bernat Romagosa
--
-- Copyright (C) 2018 by Bernat Romagosa
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

local filename = arg[1] or nil
local username = arg[2] or nil
local projectname = arg[3] or nil
local file_size
local buffer_size = tonumber(arg[3]) or 393216
local count = 0
local separator = "\3"
local file_position = 1
local file = io.open(filename, 'r')

if file then
    file_size = file:seek('end')
    file:seek('set', 0)
else
    print('Could not read ' .. filename)  
    os.exit()
end

function test_project(raw_project)
    local fields = {}
    local i = 1
    raw_project:gsub("([^".. "\2" .."]*)" .. "\2", function (field)
        fields[i] = field
        i = i + 1
    end)
    if projectname == fields[1] and username == fields[2] then
        print(fields[6])
        os.exit()
    end
end

while file_position < file_size do
    local index = nil
    local raw_item = ''
    local buffer = ''
    file:seek('set', file_position - 1)

    while not index do
        buffer = file:read(buffer_size)
        index = buffer:find(separator)
        raw_item = raw_item .. buffer:sub(1, index)
    end
    file_position = file_position + raw_item:len()
    test_project(raw_item)
    count = count + 1

    -- We may run out of memory after importing huge items, so we are forcing
    -- garbage collection after every item bigger than 5MB
    if (raw_item:len() > 5000000) then
        collectgarbage()
    end
end
print('not found')
