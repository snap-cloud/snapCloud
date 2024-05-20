-- Snap!Cloud Remixes Model
-- ========================
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
-- CREATE TABLE remixes (
--   original_project_id integer,
--   remixed_project_id integer NOT NULL,
--   created timestamp with time zone
-- );
-- CREATE INDEX original_project_id_index ON remixes USING btree (original_project_id);
-- CREATE INDEX remixed_project_id_index ON remixes USING btree (remixed_project_id);
-- ALTER TABLE ONLY remixes
--   ADD CONSTRAINT remixes_original_project_id_fkey FOREIGN KEY (original_project_id) REFERENCES public.projects(id);
-- ALTER TABLE ONLY remixes
--   ADD CONSTRAINT remixes_remixed_project_id_fkey FOREIGN KEY (remixed_project_id) REFERENCES public.projects(id);
--
local Remixes =  Model:extend('remixes', {
    primary_key = {'original_project_id', 'remixed_project_id'}
})

return Remixes
