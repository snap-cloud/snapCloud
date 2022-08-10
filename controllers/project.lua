-- Project controller
-- ==================
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2021 by Bernat Romagosa and Michael Ball
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
local capture_errors = package.loaded.capture_errors
local db = package.loaded.db
local disk = package.loaded.disk

local Projects = package.loaded.Projects
local FlaggedProjects = package.loaded.FlaggedProjects
local Collections = package.loaded.Collections
local Users = package.loaded.Users

ProjectController = {
    run_query = function (self, query)
        -- query can hold a paginator or an SQL query
        if not self.params.page_number then self.params.page_number = 1 end
        local paginator = Projects:paginated(
                 query ..
                    (self.params.search_term and (db.interpolate_query(
                        ' AND (projectname ILIKE ? OR notes ILIKE ?)',
                        '%' .. self.params.search_term .. '%',
                        '%' .. self.params.search_term .. '%')
                    ) or '') ..
                    ' ORDER BY ' ..
                        (self.params.order or 'firstpublished DESC'),
                {
                    per_page = self.params.items_per_page or 15,
                    fields = self.params.fields or '*'
                }
            )
        if not self.ignore_page_count then
            self.num_pages = paginator:num_pages()
        end

        if (self.session.app == 'snap') then
            return jsonResponse({ projects = paginator:get_all() })
        else
            local items = paginator:get_page(self.params.page_number)
            disk:process_thumbnails(items)
            return items
        end
    end,
    fetch = capture_errors(function (self)
        return ProjectController.run_query(
            self,
            [[WHERE ispublished AND NOT EXISTS(
                SELECT 1 FROM deleted_users WHERE
                username = active_projects.username LIMIT 1)]] ..
                db.interpolate_query(course_name_filter())
        )
    end),
    my_projects = capture_errors(function (self)
        self.params.order = 'lastupdated DESC'
        return ProjectController.run_query(
            self,
            db.interpolate_query('WHERE username = ?', self.session.username)
        )
    end),
    user_projects = capture_errors(function (self)
        if users_match(self) then
            return ProjectController.my_projects(self)
        else
            self.params.order = 'lastupdated DESC'
            return ProjectController.run_query(
                self,
                db.interpolate_query(
                    'WHERE ispublished AND username = ? ',
                    self.params.username
                )
            )
        end
    end),
    flagged_projects = capture_errors(function (self)
        self.params.order = 'flag_count DESC'
        self.params.fields = [[active_projects.id AS id,
            active_projects.projectname AS projectname,
            active_projects.username AS username,
            count(*) AS flag_count]]
        local query = [[INNER JOIN flagged_projects ON
                active_projects.id = flagged_projects.project_id
            WHERE active_projects.ispublic
            GROUP BY active_projects.projectname,
                active_projects.username,
                active_projects.id]]
        self.ignore_page_count = true
        if (self.num_pages == nil) then
            local total_flag_count =
                #(Projects:select(query, {fields = self.params.fields}))
            self.num_pages =
                math.ceil(total_flag_count /
                    (self.params.items_per_page or 15))
        end
        return ProjectController.run_query(self, query)
    end),
    share = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_can_share(self, project)
        project:update({
            lastupdated = db.format_date(),
            lastshared = db.format_date(),
            ispublic = true,
            ispublished = false
        })
        return okResponse()
    end),
    unshare = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_can_share(self, project)
        project:update({
            lastupdated = db.format_date(),
            ispublic = false,
            ispublished = false
        })
        return okResponse()
    end),
    publish = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_can_share(self, project)
        project:update({
            lastupdated = db.format_date(),
            firstpublished = project.firstpublished or db.format_date(),
            ispublic = true,
            ispublished = true
        })
        return okResponse()
    end),
    unpublish = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_can_share(self, project)
        project:update({
            lastupdated = db.format_date(),
            ispublished = false
        })
        return okResponse()
    end),
    metadata = function (self)
        assert_users_match(self)

        if self.current_user:isbanned() and self.params.ispublished then
            yield_error(err.banned)
        end

        local project =
            Projects:find(self.params.username, self.params.projectname)
        if not project then yield_error(err.nonexistent_project) end

        local shouldUpdateSharedDate =
            ((not project.lastshared and self.params.ispublic)
            or (self.params.ispublic and not project.ispublic))

        local result, error = project:update({
            lastupdated = db.format_date(),
            lastshared = shouldUpdateSharedDate and db.format_date() or nil,
            firstpublished =
                project.firstpublished or
                (self.params.ispublished and db.format_date()) or
                nil,
            ispublic = self.params.ispublic or project.ispublic,
            ispublished = self.params.ispublished or project.ispublished
        })

        if error then yield_error({ msg = error, status = 422 }) end

        return okResponse(
            'project ' .. self.params.projectname .. ' updated'
        )
    end,
    delete = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_can_delete(self, project)

        local username = project.username -- keep it for after deleting it

        if self.params.reason then
            send_mail(
                self.queried_user.email,
                mail_subjects.project_deleted .. project.projectname,
                mail_bodies.project_deleted .. self.current_user.role ..
                    '.</p><p>' .. self.params.reason .. '</p>')
        end

        -- Do not actually delete the project; flag it as deleted.
        if not (project:update({ deleted = db.format_date() })) then
            yield_error('Could not delete project ' ..
                self.params.projectname)
        end

        local url =
            ((username == self.current_user.username) and
                self:build_url('my_projects')
            or
                'user?username=' .. package.loaded.util.escape(username)
            )

        return jsonResponse(
            {
                title = 'Project deleted',
                message = 'Project ' .. project.projectname ..
                    ' has been deleted.',
                redirect = url
            }
        )
    end),
    flag = capture_errors(function (self)
        if self.current_user:isbanned() then yield_error(err.banned) end
        local project = Projects:find({ id = self.params.id })
        assert_project_exists(self, project)

        local flag =
            FlaggedProjects:select(
                'WHERE project_id = ? AND flagger_id = ?',
                project.id,
                self.current_user.id
            )[1]

        if flag then yield_error(err.project_already_flagged) end

        FlaggedProjects:create({
            flagger_id = self.current_user.id,
            project_id = project.id,
            reason = self.params.reason,
            notes = self.params.notes
        })

        project.flagged = true
        return okResponse()
    end),
    remove_flag = capture_errors(function (self)
        -- Check whether we're removing someone else's flag
        if self.params.flagger then assert_min_role(self, 'reviewer') end

        local project = Projects:find({ id = self.params.id })

        local flagger =
            self.params.flagger and
                Users:select('WHERE username = ?', self.params.flagger)[1] or
                self.current_user

        -- flag:delete() fails with an internal Lapis error
        if not db.delete(
                    'flagged_projects',
                    'project_id = ? AND flagger_id = ?',
                    project.id,
                    flagger.id
                ) then
            yield_error(err.project_never_flagged)
        end

        return okResponse()
    end),
    xml = capture_errors(function (self)
        local project =
            self.params.id and
                Projects:find({id = self.params.id })
            or
                Projects:find(self.params.username, self.params.projectname)

        if not project then yield_error(err.nonexistent_project) end
        if not (project.ispublic or users_match(self)) then
            assert_admin(self, err.nonexistent_project)
        end

        -- self.params.delta is a version indicator
        -- delta = null will fetch the current version
        -- delta = -1 will fetch the previous saved version
        -- delta = -2 will fetch the last version before today

        return xmlResponse(
            -- if users don't match, this project is being remixed and we
            -- need to attach its ID
            '<snapdata' .. (users_match(self) and '>' or ' remixID="' ..
                project.id .. '">') ..
                (disk:retrieve(
                    project.id, 'project.xml', self.params.delta) or
                        '<project></project>') ..
                (disk:retrieve(
                    project.id, 'media.xml', self.params.delta) or
                        '<media></media>') ..
                '</snapdata>'
        )
    end),
    thumbnail = capture_errors(function (self)
        local project =
            Projects:find(self.params.username, self.params.projectname)

        if not project then yield_error(err.nonexistent_project) end

        if not users_match(self)
            and not project.ispublic then
            yield_error(err.nonexistent_project)
        end

        -- Lazy thumbnail generation:
        -- * fetch the thumbnail if it exists, or
        -- * try to generate it and fetch it, or
        -- * fail to generate it and return an empty string

        return rawResponse(
            disk:retrieve(project.id, 'thumbnail') or
                (disk:generate_thumbnail(project.id)) or
                    '')
    end),
}
