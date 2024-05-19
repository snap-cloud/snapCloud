-- Snap!Cloud Flagged Projects Model
-- =================================
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
-- CREATE TABLE flagged_projects (
--   id integer NOT NULL,
--   flagger_id integer NOT NULL,
--   project_id integer NOT NULL,
--   reason text NOT NULL,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL,
--   notes text
-- );
-- ALTER TABLE ONLY flagged_projects
--   ADD CONSTRAINT flagged_projects_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX flagged_projects_flagger_id_project_id_idx ON flagged_projects USING btree (flagger_id, project_id);
--
local FlaggedProjects =  Model:extend('flagged_projects', {
    primary_key = 'id',
    timestamp = true
})

return FlaggedProjects
