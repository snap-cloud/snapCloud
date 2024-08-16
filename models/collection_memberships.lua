-- Snap!Cloud Collection Memberships Model
-- =======================================
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
-- CREATE TABLE collection_memberships (
--   id integer NOT NULL,
--   collection_id integer NOT NULL,
--   project_id integer NOT NULL,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL,
--   user_id integer NOT NULL
-- );
-- ALTER TABLE ONLY collection_memberships
--   ADD CONSTRAINT collection_memberships_pkey PRIMARY KEY (id);
-- CREATE INDEX collection_memberships_collection_id_idx ON collection_memberships USING btree (collection_id);
-- CREATE UNIQUE INDEX collection_memberships_collection_id_project_id_user_id_idx ON collection_memberships USING btree (collection_id, project_id, user_id);
-- CREATE INDEX collection_memberships_project_id_idx ON collection_memberships USING btree (project_id);
--
local CollectionMemberships =  Model:extend('collection_memberships', {
    primary_key = {'collection_id', 'project_id'},
    timestamp = true
})

return CollectionMemberships
