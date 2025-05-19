-- Snap!Cloud Collections Model
-- ============================
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

local db = package.loaded.db
local Model = package.loaded.Model
local escape = require('lapis.util').escape

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE collections (
--   id integer NOT NULL,
--   name text NOT NULL,
--   creator_id integer NOT NULL,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL,
--   description text,
--   published boolean DEFAULT false NOT NULL,
--   published_at timestamp with time zone,
--   shared boolean DEFAULT false NOT NULL,
--   shared_at timestamp with time zone,
--   thumbnail_id integer,
--   editor_ids integer[],
--   free_for_all boolean DEFAULT false NOT NULL
-- );
-- ALTER TABLE ONLY collections
--   ADD CONSTRAINT collections_pkey PRIMARY KEY (id);
-- CREATE INDEX collections_creator_id_idx ON collections USING btree (creator_id);
--
local Collections =  Model:extend('collections', {
    type = 'collection',
    primary_key = {'creator_id', 'name'},
    timestamp = true,
    url_for = function (self, purpose)
        if not self.username then
            if not self.creator then
                self.creator = package.loaded.Users:find(self.creator_id)
            end
            self.username = self.creator.username
        end
        local urls = {
            site = '/collection?username=' .. escape(self.username) ..
                '&collection=' .. escape(self.name),
            author = '/user?username=' .. escape(self.username)
        }
        return urls[purpose]
    end,
    relations = {
        -- creates Collection:get_creator()
        {'creator', belongs_to = 'Users', key = 'creator_id'},
        {'memberships', has_many = 'CollectionMemberships'},
        {'projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                        AS memberships
                        ON active_projects.id = memberships.project_id
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'shared_and_published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                        AS memberships
                        ON active_projects.id = memberships.project_id
                        WHERE (ispublished OR ispublic)
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                        AS memberships
                        ON active_projects.id = memberships.project_id
                        WHERE ispublished
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        }
    },
    constraints = {
        name = function(self, value)
            if not value then
                return 'A name must be present'
            end
        end
    },
    count_projects = function (self)
        return package.loaded.CollectionMemberships:count('collection_id = ?',
                                                          self.id)
    end
})

return Collections
