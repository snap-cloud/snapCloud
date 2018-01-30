-- Migration utility
-- =================
--
-- This utility helps migrate records from the old cloud into the new one.
-- Not meant to be used from Lapis but as a command-line utility.
--
-- written by Bernat Romagosa
--
-- Copyright (C) 2017 by Bernat Romagosa
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

local pgmoon = require('pgmoon')
local url = os.getenv('DATABASE_URL')
local table = arg[1] or nil
local filename = arg[2] or nil
local file = io.open(filename, 'r')
local file_size
local buffer_size = tonumber(arg[3]) or 524288 -- Seems to be the sweet spot in my system
local usage = 'Usage:\n\nlua migrate.lua [users/projects] [file.xml]\n'

require 'disk'

local db = pgmoon.new({
    host = url:match("([^:]*)"), -- only up to ":"
    port = url:match("^.*%:(.*)"), -- after ":"
    database = os.getenv('DATABASE_NAME'),
    user = os.getenv('DATABASE_USERNAME'),
    password = os.getenv('DATABASE_PASSWORD')
})

assert(db:connect())

if not (arg[1] and arg[2]) then
    print(usage)
end

if file then
    file_size = file:seek('end')
    file:seek('set', 0)
else
    print('Could not read ' .. filename)  
    print(usage)
    os.exit()
end

function migrate_collection(entities)
    local separator = {
        users = "\0",
        projects = "\3"
    }

    local file_position = 1

    while file_position < file_size do
        local index = nil
        local raw_item = ''
        local buffer = ''
        file:seek('set', file_position - 1)

        while not index do
            buffer = file:read(buffer_size)
            index = buffer:find(separator[entities])
            raw_item = raw_item .. buffer:sub(1, index)
        end
        file_position = file_position + raw_item:len()
        _G['migrate_' .. entities:sub(1, -2)](raw_item)
    end
    print('all done')
end

function migrate_user(raw_user)
    local fields = {}
    local i = 1
    raw_user:gsub("([^".. "\1" .."]*)" .. "\1", function (field)
        fields[i] = field
        i = i + 1
    end)

    print('migrating user ' .. fields[2])
    print(db:query("insert into users (created, username, salt, password, email, isadmin) values (" ..
        "'" .. fields[8] .. "', " ..
        "'" .. fields[2] .. "', " ..
        "'" .. fields[5] .. "', " ..
        "'" .. fields[4] .. "', " ..
        "'" .. fields[3] .. "', " ..
        "false);"))
end

function migrate_project(raw_project)
    -- STILL UNTESTED
    local fields = {}
    local i = 1
    raw_project:gsub("([^".. "\2" .."]*)" .. "\2", function (field)
        fields[i] = field
        i = i + 1
    end)

    print('migrating project ' .. fields[1])

    --[[
    print(db:query("insert into projects (projectname, username, ispublic, ispublished, created, lastupdated, lastshared) values (" ..
        "'" .. fields[1] .. "', " ..
        "'" .. fields[2] .. "', " ..
        fields[3] .. ', false, ' ..
        "'" .. fields[4] .. "', " ..
        "'" .. fields[4] .. "', " ..
        ((fields[3] == 'true') and ("'" .. fields[4] .. "';" ) or "NULL;")
        ))

    -- We need to get the project ID by asking the DB. Maybe the query returns it?
    saveToDisk(project_id, 'project.xml', fields[6])
    -- To get the thumbnail, we need to parse the XML and extract the <thumbnail>
    -- tag contents
    saveToDisk(project_id, 'thumbnail', thumbnail)
    -- We need to find the media XML from the media file. We could probably just
    -- concatenate it into the project XML and forget about this extra file, or
    -- import all media altogether later
    saveToDisk(project.id, 'media.xml', get_media(fields[1], fields[2])) 
    --]]
end

--local time = os.time()
_G['migrate_collection'](table)
--print(os.time() - time)
