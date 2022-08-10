-- Project API controller
-- ======================
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
local validate = package.loaded.validate
local db = package.loaded.db
local cached = package.loaded.cached
local yield_error = package.loaded.yield_error
local cjson = require('cjson')

local Projects = package.loaded.Projects
local Users = package.loaded.Users
local DeletedProjects = package.loaded.DeletedProjects

local disk = package.loaded.disk

require 'responses'
require 'validation'

ProjectController = {
    POST = {
        project = function (self)
            -- POST /projects/:username/:projectname
            -- Description: Add/update a particular project.
            --              Response will depend on query issuer permissions.
            -- Body:        xml, notes, thumbnail

            rate_limit(self)

            validate.assert_valid(self.params, {
                { 'projectname', exists = true },
                { 'username', exists = true }
            })

            assert_all({assert_user_exists, assert_users_match}, self)

            -- Read request body and parse it into JSON
            ngx.req.read_body()
            local body_data = ngx.req.get_body_data()
            local body = body_data and util.from_json(body_data) or nil

            validate.assert_valid(body, {
                { 'xml', exists = true },
                { 'thumbnail', exists = true },
                { 'media', exists = true }
            })

            local project =
                Projects:find(self.params.username, self.params.projectname)

            if (project) then
                local shouldUpdateSharedDate =
                    ((not project.lastshared and self.params.ispublic)
                    or (self.params.ispublic and not project.ispublic))

                disk:backup_project(project.id)

                project:update({
                    lastupdated = db.format_date(),
                    lastshared =
                        shouldUpdateSharedDate and db.format_date() or nil,
                    firstpublished =
                        project.firstpublished or
                        (self.params.ispublished and db.format_date()) or
                        nil,
                    notes = body.notes,
                    ispublic = self.params.ispublic or project.ispublic,
                    ispublished = self.params.ispublished or project.ispublished
                })
            else
                -- Users are automatically verified the first time
                -- they save a project
                if (not self.queried_user.verified) then
                    self.queried_user:update({ verified = true })
                    self.session.verified = true
                end

                -- A project flagged as "deleted" with the same name may exist
                -- in the DB.
                -- We need to check for that and delete it for real this time
                local deleted_project = DeletedProjects:find(
                    self.params.username, self.params.projectname)
                -- Deleted project may have remixes or be included in a
                -- collection. Let's take care of this.
                if deleted_project then
                    db.query(
                        'DELETE FROM Remixes WHERE '..
                            'original_project_id = ? OR remixed_project_id = ?',
                        deleted_project.id,
                        deleted_project.id)
                    db.query(
                        'DELETE FROM Collection_Memberships WHERE ' ..
                            'project_id = ?',
                        deleted_project.id)
                    deleted_project:delete()
                end
                Projects:create({
                    projectname = self.params.projectname,
                    username = self.params.username,
                    created = db.format_date(),
                    lastupdated = db.format_date(),
                    lastshared = self.params.ispublic and
                        db.format_date() or nil,
                    firstpublished = self.params.ispublished
                        and db.format_date() or nil,
                    notes = body.notes,
                    ispublic = self.params.ispublic or false,
                    ispublished = self.params.ispublished or false
                })
                project =
                    Projects:find(self.params.username, self.params.projectname)

                if (body.remixID and body.remixID ~= cjson.null) then
                    -- user is remixing a project
                    Remixes:create({
                        original_project_id = body.remixID,
                        remixed_project_id = project.id,
                        created = db.format_date()
                    })
                end
            end

            disk:save(project.id, 'project.xml', body.xml)
            disk:save(project.id, 'thumbnail', body.thumbnail)
            disk:save(project.id, 'media.xml', body.media)

            if not (disk:retrieve(project.id, 'project.xml')
                and disk:retrieve(project.id, 'thumbnail')
                and disk:retrieve(project.id, 'media.xml')) then
                yield_error('Could not save project ' ..
                    self.params.projectname)
            else
                return okResponse('project ' .. self.params.projectname ..
                    ' saved')
            end
        end,
    },
}
