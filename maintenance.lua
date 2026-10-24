-- Maintenance mode
-- ================
--
-- Set with `bin/maintenance-mode` (which edits .env, locks the database and
-- restarts the app). The mode is read once, at server start:
--
--   MAINTENANCE_MODE=read_only  Pages and GET requests work. The database is
--                               read-only, so anything that would write fails
--                               with a maintenance message. Logged-in users
--                               stay logged in.
--   MAINTENANCE_MODE=down       (or `true`) Every request gets a 503.
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

local config = package.loaded.config
local maintenance = {}

-- nil (normal), 'read_only' or 'down'. `true` was the old setting for down.
local modes = { read_only = 'read_only', down = 'down', ['true'] = 'down' }
maintenance.mode = modes[config.maintenance_mode]

if maintenance.mode == 'down' then
    maintenance.message =
        'The Snap!Cloud is down for maintenance. Please try again soon.'
else
    maintenance.message =
        'The Snap!Cloud is in read-only mode for maintenance, so changes ' ..
        "can't be saved right now. Please try again soon. To keep your " ..
        'work, use File > Export project to save it to your computer.'
end

-- Postgres error when writing to a read-only database (default_transaction_read_only).
function maintenance.is_read_only_db_error(err)
    return type(err) == 'string' and
        err:find('read%-only transaction') ~= nil
end

-- A 503 in the right format: an HTML page for browsers, JSON ({errors = {msg}})
-- for the Snap! editor and other API clients.
function maintenance.response(self)
    local headers = self.req and self.req.headers
    local accept = headers and headers['accept'] or ''
    if type(accept) == 'table' then accept = table.concat(accept, ',') end
    if accept:match('text/html') then
        return html_message_page(
            self, 'Down for maintenance',
            '<p>' .. require('lib.util').escape_html(maintenance.message) ..
            '</p>', 503)
    end
    return {
        layout = false,
        status = 503,
        readyState = 4,
        json = { errors = { maintenance.message } }
    }
end

return maintenance
