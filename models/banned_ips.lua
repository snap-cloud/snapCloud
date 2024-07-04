-- Snap!Cloud Banned IPs Model
-- ===========================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local Model = package.loaded.Model

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE banned_ips (
--   ip text NOT NULL,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL,
--   offense_count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY banned_ips
--   ADD CONSTRAINT banned_ips_pkey PRIMARY KEY (ip);
--
local BannedIPs = Model:extend ('banned_ips', {
    primary_key = 'ip',
    timestamp = true
})

return BannedIPs
