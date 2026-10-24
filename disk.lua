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

-- Largest buffer we read or write at once. Bounds peak memory per request:
-- copy_file streams in COPY_CHUNK-sized pieces rather than holding a whole
-- (possibly multi-megabyte) project file in the worker's Lua heap at once.
local COPY_CHUNK = 65536 -- 64 KB

-- A temp path beside `path`, unique per worker and per call, so two requests
-- writing the same project file (e.g. a double save) never share a .tmp.
local tmp_seq = 0
local function temp_name (path)
    tmp_seq = tmp_seq + 1
    local pid = (ngx and ngx.worker and ngx.worker.pid and ngx.worker.pid())
        or 0
    return string.format('%s.%d.%d.tmp', path, pid, tmp_seq)
end

-- Write contents to path atomically: fill a sibling temp file, then rename it
-- over path. rename(2) within a directory is atomic, so a crash or OOM
-- mid-write can never leave a truncated or empty file where a good one was --
-- a reader sees either the whole old contents or the whole new, never a mix.
-- Returns true, or false plus a message (leaving path untouched).
local function write_file_atomic (path, contents)
    local tmp = temp_name(path)
    local output, message = io.open(tmp, 'wb')
    if not output then return false, message end
    output:write(contents)
    output:close()
    local ok, err = os.rename(tmp, path)
    if not ok then
        os.remove(tmp)
        return false, err
    end
    return true
end

-- Copy a single file, preserving its timestamps like `cp -p` would.
-- backup_project relies on the modification time to tell versions apart.
-- Streams through a fixed buffer and renames into place, so a large project
-- neither spikes worker memory nor leaves a partial copy behind on failure.
local function copy_file (source, destination)
    local input = io.open(source, 'rb')
    if not input then return false end
    local tmp = temp_name(destination)
    local output = io.open(tmp, 'wb')
    if not output then
        input:close()
        return false
    end
    while true do
        local chunk = input:read(COPY_CHUNK)
        if not chunk then break end
        output:write(chunk)
    end
    input:close()
    output:close()
    if not os.rename(tmp, destination) then
        os.remove(tmp)
        return false
    end
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

-- How many previous versions of each project we keep. They live in folders
-- named d-1 to d-N inside the project's directory:
--   d-1: the version from right before the latest save
--   d-2: the last version that was more than 12 hours old
-- A "delta" is the number that picks one: nil or 0 for the current version,
-- -1 to -BACKUP_VERSIONS for a backup.
disk.BACKUP_VERSIONS = 2

-- Returns the directory holding the given version of a project.
-- delta often comes straight from a request param and ends up in a file path,
-- so anything that isn't a known version is rejected.
function disk:version_directory (id, delta)
    local dir = self:directory_for_id(id)
    if delta == nil or delta == '' then return dir end
    local version = tonumber(delta)
    if version == 0 then return dir end
    if version == nil or version ~= math.floor(version) or
            version > 0 or version < -disk.BACKUP_VERSIONS then
        yield_error(err.invalid_project_version)
    end
    return dir .. string.format('/d%d', version)
end

-- Rendered in place of a real thumbnail when project.xml can't be parsed.
disk.missing_thumbnail = '/static/img/missing-thumbnail.svg'

local function report_thumbnail_failure(id, reason)
    -- Lazy-require: disk.lua loads before lib.exceptions in app.lua.
    local ok, exceptions = pcall(require, 'lib.exceptions')
    if not ok or not exceptions.rvn then return end
    exceptions.rvn:captureMessage(
        'Thumbnail generation failed for project id=' .. tostring(id),
        {
            level = 'warning',
            tags = { component = 'disk.generate_thumbnail' },
            extra = { project_id = id, reason = tostring(reason) },
        }
    )
end

-- Safely parse a project.xml buffer. Returns (doc, err): the parsed table on
-- success, nil on a parse failure (with the lubyk error in `err`), or
-- nil/nil if the file is empty or whitespace-only. Strips embedded NULs
-- first because lubyk's Lua->C bridge truncates the buffer at the first \0
-- and masks otherwise-valid XML behind "unexpected end of data" -- any NULs
-- found are reported to Sentry against `id` since they signal corruption.
local function protected_load_xml(id, raw)
    local contents, nuls = (raw or ''):gsub('%z', '')
    if nuls > 0 then
        report_thumbnail_failure(id,
            'stripped ' .. nuls .. ' NUL byte(s) from project.xml')
    end
    -- Empty / whitespace-only input would segfault or error in lubyk; treat
    -- it as "nothing to parse" rather than a load failure.
    if not contents:find('%S') then return nil end
    local ok, result = pcall(xml.load, contents)
    if ok then return result end
    return nil, result
end

function disk:directory_for_id (id)
    return config.store_path .. '/' .. math.floor(id / 1000) .. '/' .. id
end

function disk:save (id, filename, contents)
    local dir = self:directory_for_id(id)
    mkdir_p(dir)
    -- Atomic write: a worker that dies mid-save (e.g. OOM on a large media.xml)
    -- leaves the previous good file in place rather than a truncated one.
    write_file_atomic(dir .. '/' .. filename, contents)
end

function disk:retrieve (id, filename, delta)
    local dir = self:version_directory(id, delta)
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
    if not project_file then return end
    local raw = project_file:read('*all')
    project_file:close()

    local project, err = protected_load_xml(id, raw)
    if err then
        report_thumbnail_failure(id, err)
        return
    end
    if not project then return end

    local found = xml.find(project, 'thumbnail')
    local thumbnail = found and found[1]
    if not thumbnail then
        report_thumbnail_failure(id, 'no <thumbnail> in project.xml')
        return
    end

    self:save(id, 'thumbnail', thumbnail)
    return thumbnail
end

function disk:parse_notes (id, delta)
    local dir = self:version_directory(id, delta)
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
                write_file_atomic(dir .. '/project.xml', xml.dump(project))
            end)
        if success then
            project_file = io.open(dir .. '/project.xml', 'r')
            local contents = project_file:read('*all')
            if #contents == 0 then
                -- File length is zero! File got corrupted somehow.
                -- Let's recover the previous delta, which was backed up right
                -- before attempting to update the XML.
                local backup = self:retrieve(id, 'project.xml', '-1')
                write_file_atomic(dir .. '/project.xml', backup)
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
    local dir = self:version_directory(id, delta)
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
                self:generate_thumbnail(item[id_selector or 'id']) or
                self.missing_thumbnail
        end
    end
end

function disk:save_totm_banner (file)
    write_file_atomic('static/img/totm.png', file.content)
    return true
end

return disk
