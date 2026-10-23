-- Maintenance mode
-- ================
--
-- Turned on and off with `bin/maintenance-mode`, which writes a flag file.
-- The app checks the file on each request (cached for a second per worker),
-- so no restart is needed.
--
--   read_only  Pages and GET API requests work. Anything that would write
--              (POST/PUT/DELETE/PATCH, and the few GET routes that write)
--              gets a 503 with an explanation. Logged-in users stay logged
--              in, but logins and session tracking are paused.
--   down       Every request gets a 503 maintenance message.
--
-- MAINTENANCE_MODE=true in .env also means `down` (read at server start).
--
-- Copyright (C) 2026 by Michael Ball
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

local maintenance = {}

-- Relative to the nginx prefix (the snapCloud directory). Matches bin/maintenance-mode.
maintenance.flag_file = 'tmp/maintenance_mode'

local CHECK_INTERVAL = 1 -- seconds
local cached_mode, cached_note, checked_at = nil, nil, -1

local function flag_path()
    local prefix = ngx and ngx.config and ngx.config.prefix() or ''
    return prefix .. maintenance.flag_file
end

-- Flag file format: first word is the mode, the rest of the first line is an
-- optional note shown to users (e.g. "until about 09:00 PT").
local function read_flag()
    local file = io.open(flag_path(), 'r')
    if not file then return nil, nil end
    local line = file:read('*l') or ''
    file:close()
    local mode, note = line:match('^%s*(%S*)%s*(.-)%s*$')
    if mode == '' then mode = 'read_only' end
    if mode ~= 'read_only' and mode ~= 'down' then mode = 'read_only' end
    if note == '' then note = nil end
    return mode, note
end

-- Returns nil (normal), 'read_only' or 'down', plus the optional note.
function maintenance.mode()
    local now = ngx.now()
    if now - checked_at >= CHECK_INTERVAL then
        checked_at = now
        cached_mode, cached_note = read_flag()
    end
    if not cached_mode and package.loaded.config.maintenance_mode == 'true' then
        return 'down', cached_note
    end
    return cached_mode, cached_note
end

-- True in both read_only and down: nothing may be written.
function maintenance.is_read_only()
    return maintenance.mode() ~= nil
end

local function with_note(text, note)
    if note then return text .. ' (' .. note .. ')' end
    return text
end

function maintenance.message()
    local mode, note = maintenance.mode()
    if mode == 'down' then
        return with_note(
            'The Snap!Cloud is down for maintenance. Please try again soon.',
            note)
    end
    return with_note(
        'The Snap!Cloud is in read-only mode for maintenance, so changes ' ..
        "can't be saved right now. Please try again soon. To keep your " ..
        'work, use File > Export project to save it to your computer.',
        note)
end

local SAFE_METHODS = { GET = true, HEAD = true, OPTIONS = true }

function maintenance.allows_method(method)
    return SAFE_METHODS[method] == true
end

-- A 503 response in the right format: an HTML page for browsers, JSON
-- ({errors = {msg}}) for the Snap! editor and other API clients.
function maintenance.response(self)
    local message = maintenance.message()
    if self.res and self.res.headers then
        self.res.headers['Retry-After'] = '600'
    end
    local headers = self.req and self.req.headers
    local accept = headers and headers['accept'] or ''
    if type(accept) == 'table' then accept = table.concat(accept, ',') end
    if accept:match('text/html') then
        return html_message_page(
            self, 'Down for maintenance',
            '<p>' .. require('lib.util').escape_html(message) .. '</p>', 503)
    end
    return {
        layout = false,
        status = 503,
        readyState = 4,
        json = { errors = { message } }
    }
end

-- For GET routes that write: returns a 503 response while in maintenance,
-- or nil. Usage: `local blocked = maintenance.block_writes(self)
--                 if blocked then return blocked end`
function maintenance.block_writes(self)
    if maintenance.is_read_only() then
        return maintenance.response(self)
    end
end

return maintenance
