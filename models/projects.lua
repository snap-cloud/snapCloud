-- Snap!Cloud Projects Model
-- =========================
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
local disk = package.loaded.disk

-- Generated schema dump: (do not edit)
--
-- CREATE VIEW active_projects AS
--  SELECT projects.id,
--   projects.projectname,
--   projects.ispublic,
--   projects.ispublished,
--   projects.notes,
--   projects.created,
--   projects.lastupdated,
--   projects.lastshared,
--   projects.username,
--   projects.firstpublished,
--   projects.deleted
--    FROM public.projects
--   WHERE (projects.deleted IS NULL);
--
local ActiveProjects =  Model:extend('active_projects', {
    type = 'project',
    primary_key = {'username', 'projectname'},
    constraints = {
        projectname = function (_self, name)
            if not name or string.len(name) < 1 then
                return "Project names must have at least one character."
            end
        end
    },
    url_for = function (self, purpose, dev_version)
        local base = 'https://snap.berkeley.edu/' ..
            (dev_version and 'snapsource/dev/' or '') ..
            'snap.html'
        local urls = {
            viewer = base ..
                '#present:Username=' .. escape(self.username) ..
                '&ProjectName=' .. escape(self.projectname) ..
                '&embedMode&noExitWarning&noRun',
            open = base ..
                '#present:Username=' .. escape(self.username) ..
                '&ProjectName=' .. escape(self.projectname) ..
                '&editMode&noRun',
            download = '/project/' .. escape(self.id),
            site = '/project?username=' .. escape(self.username) ..
                '&projectname=' .. escape(self.projectname),
            author = '/user?username=' .. escape(self.username),
            embed = 'https://snap.berkeley.edu/embed?projectname=' ..
                escape(self.projectname) .. '&username=' ..
                escape(self.username)
        }
        return urls[purpose]
    end,
    relations = {
        {'flags',
            fetch = function (self)
                return package.loaded.FlaggedProjects:select(
                    'JOIN active_users ON active_users.id = flagger_id '..
                    'WHERE project_id = ? ' ..
                    'GROUP BY reason, username, created_at, notes',
                    self.id,
                    { fields = 'username, created_at, reason, notes' }
                )
            end
        },
        {'public_remixes',
            fetch = function (self)
                local items = package.loaded.Projects:select(
                   [[JOIN remixes
                        ON active_projects.id = remixes.remixed_project_id
                    WHERE remixes.original_project_id = ?
                    AND ispublic]],
                    self.id
                )
                disk:process_thumbnails(items)
                return items
            end
        },
        {'public_collections',
            fetch = function (self)
                local items = package.loaded.Collections:select(
                    [[INNER JOIN collection_memberships
                        ON collection_memberships.collection_id = collections.id
                    INNER JOIN users
                        ON collections.creator_id = users.id
                    WHERE collection_memberships.project_id = ?
                    AND collections.published]],
                    self.id
                )
                disk:process_thumbnails(items, 'thumbnail_id')
                return items
            end
        }
    }
})

package.loaded.DeletedProjects = Model:extend('deleted_projects', {
    primary_key = {'username', 'projectname'}
})

package.loaded.Projects = ActiveProjects
return ActiveProjects
