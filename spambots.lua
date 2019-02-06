-- SpamBot API controller
-- ======================
-- When someone attempts to access well-known spam/exploit paths, we add
-- them to the banned_ips table
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

local util = package.loaded.util
local db = package.loaded.db
local yield_error = package.loaded.yield_error

local BannedIPs = package.loaded.BannedIPs

require 'responses'

local app = package.loaded.app
local capture_errors = package.loaded.capture_errors
local respond_to = package.loaded.respond_to

local suspicious_paths = {
    '/manager(/:*)',
    '/(*).php',
    '/(*).cfm',
    '/(*).asp',
    '/(*).do',
    '/(*).env',
    '/(*).action',
    '/(*).jsp',
    '/mysql(*)',
    '/.backup(*)',
    '/.env(*)',
    '/.git(*)',
    '/.hidden(*)',
    '/.svn(*)',
    '/.vscode(*)',
    '/Admin(*)',
    '/admin(*)',
    '/DB(*)',
    '/MySQL(*)',
    '/MySQL(*)',
    '/cgi-bin(*)',
    '/cf_scripts(*)'
}

for _, path in pairs(suspicious_paths) do
    app:match(path, function (self) 
        -- Check whether this IP is already in the black list.
        -- If it is, increment their offense_count.
        -- IPs with offense_count == 3 are permabanned.
        local ip = ngx.var.remote_addr
        local ip_entry = BannedIPs:find(ip)

        if ip_entry then
            ip_entry:update({ offense_count = ip_entry.offense_count + 1 })
        else
            ip_entry = BannedIPs:create({
                ip = ip,
                offense_count = 1
            })
        end

        if (ip_entry.offense_count < 3) then
            return errorResponse(
            'You are attempting to access a well known spam / exploit path. ' ..
            'Your IP will be banned from this system if this incident ' ..
            'happens ' .. tostring(3 - ip_entry.offense_count) .. ' more times',
            400)
        else
            return { redirect_to = self:build_url('/') }
        end
    end
    )
end
