-- Snap!Cloud Featured Collections Model
-- =====================================
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
-- CREATE TABLE featured_collections (
--   collection_id integer NOT NULL,
--   page_path text NOT NULL,
--   type text NOT NULL,
--   "order" integer DEFAULT 0 NOT NULL,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL
-- );
-- ALTER TABLE ONLY featured_collections
--   ADD CONSTRAINT featured_collections_pkey PRIMARY KEY (collection_id, page_path);
--
local FeaturedCollections =  Model:extend('featured_collections', {
    primary_key = {'collection_id', 'page_path'},
    timestamp = true
})

return FeaturedCollections
