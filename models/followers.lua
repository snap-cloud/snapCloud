-- Snap!Cloud Followers Model
-- ==========================
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
-- CREATE TABLE followers (
--   follower_id integer NOT NULL,
--   followed_id integer NOT NULL,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL
-- );
-- ALTER TABLE ONLY followers
--   ADD CONSTRAINT followers_pkey PRIMARY KEY (follower_id, followed_id);
--
local Followers =  Model:extend('followers', {
    primary_key = {'follower_id', 'followed_id'},
    timestamp = true
})

return Followers
