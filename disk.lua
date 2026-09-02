-- Disk storage utils
-- ==================
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


-- we store max 1000 projects per dir

local xml = require("xml")
local lfs = require("lfs")
local config = package.loaded.config
local yield_error = package.loaded.yield_error

local disk = {}

-- File system helpers
-- -------------------
-- All of these are pure Lua (via LuaFileSystem) so that no path is ever
-- handed to a shell.

-- Create path and any missing parent directories, like `mkdir -p`.
local function mkdir_p (path)
    local current = path:sub(1, 1) == '/' and '/' or ''
    for component in path:gmatch('[^/]+') do
        current = current .. component
        if not lfs.attributes(current, 'mode') then
            local ok, message = lfs.mkdir(current)
            -- another request may have just created it, which is fine
            if not ok and not lfs.attributes(current, 'mode') then
                return false, message
            end
        end
        current = current .. '/'
    end
    return true
end

-- Seconds since the epoch at which path was last modified, or nil if it
-- doesn't exist.
local function last_modified (path)
    return lfs.attributes(path, 'modification')
end

-- Copy a single file, preserving its timestamps like `cp -p` would.
-- backup_project relies on the modification time to tell versions apart.
local function copy_file (source, destination)
    local input = io.open(source, 'rb')
    if not input then return false end
    local output = io.open(destination, 'wb')
    if not output then
        input:close()
        return false
    end
    output:write(input:read('*all'))
    input:close()
    output:close()
    local attributes = lfs.attributes(source)
    if attributes then
        lfs.touch(destination, attributes.access, attributes.modification)
    end
    return true
end

-- Copy the project files (every *.xml plus the thumbnail) in dir into
-- backup_dir, creating it if needed.
local function copy_project_files (dir, backup_dir)
    if lfs.attributes(dir, 'mode') ~= 'directory' then return false end
    mkdir_p(backup_dir)
    for entry in lfs.dir(dir) do
        if entry:match('%.xml$') or entry == 'thumbnail' then
            copy_file(dir .. '/' .. entry, backup_dir .. '/' .. entry)
        end
    end
    return true
end

function disk:directory_for_id (id)
    return config.store_path .. '/' .. math.floor(id / 1000) .. '/' .. id
end

function disk:save (id, filename, contents)
    local dir = self:directory_for_id(id)
    mkdir_p(dir)
    local file = io.open(dir .. '/' .. filename, 'w+')
    if (file) then
        file:write(contents)
        file:close()
    end
end

function disk:retrieve (id, filename, delta)
    local dir = self:directory_for_id(id)
    -- if delta exists, we look for a previous version of the file
    -- under dir/d[delta]
    if (delta) then dir = dir .. '/d' .. delta end
    local file = io.open(dir .. '/' .. filename, 'r')
    if (file) then
        local contents = file:read("*all")
        file:close()
        return contents
    else
        return nil
    end
end

function disk:retrieve_thumbnail (id)
    return self:retrieve(id, 'thumbnail')
end

function disk:generate_thumbnail (id)
    local project_file = io.open(self:directory_for_id(id) .. '/project.xml')
    if (project_file) then
        local project = xml.load(project_file:read('*all'))
        local thumbnail = xml.find(project, 'thumbnail')[1]
        project_file:close()
        self:save(id, 'thumbnail', thumbnail)
        return thumbnail
    else
        return false
    end
end

function disk:parse_notes (id, delta)
    local dir = self:directory_for_id(id)
    -- if delta exists, we look for a previous version of the file
    -- under dir/d[delta]
    if (delta) then dir = dir .. '/d' .. delta end
    local project_file = io.open(dir .. '/project.xml', 'r')
    local notes
    if (project_file) then
        if pcall(
            function ()
                local project = xml.load(project_file:read('*all'))
                notes = xml.find(project, 'notes')[1]
            end) then
            project_file:close()
            return notes or ''
        else
            project_file:close()
            return ''
        end
    else
        return ''
    end
end

function disk:update_notes (id, notes)
    self:update_xml(id, function (project)
        local old_notes = xml.find(project, 'notes')
        old_notes[1] = notes
    end)
end

function disk:update_name(id, name)
    self:update_xml(id, function (project)
        project.name = name
    end)
end

function disk:update_metadata(id, name, notes)
    self:update_xml(id, function (project)
        project.name = name
        local old_notes = xml.find(project, 'notes')
        old_notes[1] = notes
    end)
end

function disk:update_xml(id, update_function)
    local dir = self:directory_for_id(id)
    local project_file = io.open(dir .. '/project.xml', 'r')
    if (project_file) then
        local success, message = pcall(
            function ()
                local project = xml.load(project_file:read('*all'))
                project_file:close()
                self:backup_project(id)
                update_function(project)
                project_file = io.open(dir .. '/project.xml', 'w+')
                project_file:write(xml.dump(project))
                project_file:close()
            end)
        if success then
            project_file = io.open(dir .. '/project.xml', 'r')
            local contents = project_file:read('*all')
            if #contents == 0 then
                -- File length is zero! File got corrupted somehow.
                -- Let's recover the previous delta, which was backed up right
                -- before attempting to update the XML.
                project_file = io.open(dir .. '/project.xml', 'w+')
                local backup = self:retrieve(id, 'project.xml', '-1')
                project_file:write(backup)
                project_file:close()
                yield_error(err.update_project_fail)
            else
                project_file:close()
            end
        else
            if project_file then project_file:close() end
            ngx.log(message)
            yield_error(err.unparseable_xml .. tostring(message))
        end
    else
        yield_error(err.file_not_found)
    end
end

function disk:get_version_metadata(id, delta)
    local dir = self:directory_for_id(id) .. '/d' .. delta
    local modified = last_modified(dir .. '/project.xml')
    if modified then
        return {
            notes = self:parse_notes(id, delta),
            thumbnail = self:retrieve(id, 'thumbnail', delta),
            -- seconds since last modification
            lastupdated = os.time() - modified,
            delta = delta
        }
    else
        return nil
    end
end

function disk:backup_project(id)
    -- This function is called right before saving a project
    local dir = self:directory_for_id(id)

    -- We always save the current copy into the /d-1 folder
    copy_project_files(dir, dir .. '/d-1')
    -- If the current project was modified more than 12 hours ago,
    -- we save it into the /d-2 folder
    local modified = last_modified(dir .. '/project.xml')
    if modified and (os.time() - modified > 43200) then
        copy_project_files(dir, dir .. '/d-2')
    end
end

function disk:process_notes (projects)
    -- Lazy Notes generation
    for _, project in pairs(projects) do
        if (project.notes == nil) then
            local notes = self:parse_notes(project.id)
            if notes then
                project:update({ notes = notes })
                project.notes = notes
            end
        end
    end
end

function disk:process_thumbnails (items, id_selector)
    -- Lazy Thumbnail generation
    for _, item in pairs(items) do
        if (item[id_selector or 'id']) then
            item.thumbnail =
                self:retrieve_thumbnail(item[id_selector or 'id']) or
                self:generate_thumbnail(item[id_selector or 'id'])
        end
    end
end

function disk:save_totm_banner (file)
    local totm_file = io.open('static/img/totm.png', 'w')
    totm_file:write(file.content)
    totm_file:close()
    return true
end

return disk
