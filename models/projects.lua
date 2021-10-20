-- Projects Model
-- ==============
--
-- A cloud backend for Snap!
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local db = package.loaded.db
local Model = require('lapis.db.Model').Model

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE projects (
--   id integer NOT NULL,
--   projectname text NOT NULL,
--   ispublic boolean,
--   ispublished boolean,
--   notes text,
--   created timestamp with time zone,
--   lastupdated timestamp with time zone,
--   lastshared timestamp with time zone,
--   username public.dom_username NOT NULL,
--   firstpublished timestamp with time zone,
--   deleted timestamp with time zone
-- );
-- ALTER TABLE ONLY projects
--   ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);
-- ALTER TABLE ONLY projects
--   ADD CONSTRAINT unique_id UNIQUE (id);
-- ALTER TABLE ONLY projects
--   ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);
-- End projects schema
--
local Projects = Model:extend('active_projects', {
    primary_key = {'username', 'projectname'},
    constraints = {
        projectname = function (_self, name)
            if not name or string.len(name) < 1 then
                return "Project names must have at least one character."
            end
        end
    }
})

package.loaded.DeletedProjects = Model:extend('deleted_projects', {
    primary_key = {'username', 'projectname'}
})

package.loaded.Projects = Projects
return package.loaded.Projects
