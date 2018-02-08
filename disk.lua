-- Disk storage utils
-- ==================
--
-- Written by Bernat Romagosa
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


-- we store max 1000 projects per dir

local xml = require("xml")
local config = package.loaded.config

function directory_for_id(id)
    return config.store_path .. '/' .. math.floor(id / 1000) .. '/' .. id
end

function save_to_disk(id, filename, contents)
    local dir = directory_for_id(id)
    os.execute('mkdir -p ' .. dir)
    local file = io.open(dir .. '/' .. filename, 'w+')
    if (file) then
        file:write(contents)
        file:close()
    end
end

function retrieve_from_disk(id, filename)
    local dir = directory_for_id(id)
    local file = io.open(dir .. '/' .. filename, 'r')
    if (file) then
        local contents = file:read("*all")
        file:close()
        return contents
    else
        return nil
    end
end

function delete_directory(id)
    os.execute('rm -r ' .. directory_for_id(id))
end

function generate_thumbnail(id)
    local project_file = io.open(directory_for_id(id) .. '/project.xml')
    if (project_file) then
        local project = xml.load(project_file:read('*all'))
        local thumbnail = xml.find(project, 'thumbnail')[1]
        project_file:close()
        save_to_disk(id, 'thumbnail', thumbnail)
        return thumbnail
    else
        return false
    end
end

function parse_notes(id)
    local project_file = io.open(directory_for_id(id) .. '/project.xml')
    local notes
    if (project_file) then
        if pcall(
            function ()
                local project = xml.load(project_file:read('*all'))
                notes = xml.find(project, 'notes')[1]
            end) then
            return notes
        else
            return nil
        end
    else
        return nil
    end
end
