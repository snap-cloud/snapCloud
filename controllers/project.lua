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
local cached_query = package.loaded.cached_query
local uncache_category = package.loaded.uncache_category
local yield_error = package.loaded.yield_error
local capture_errors = package.loaded.capture_errors
local db = package.loaded.db
local disk = package.loaded.disk
local cjson = package.loaded.cjson

local Projects = package.loaded.Projects
local Remixes = package.loaded.Remixes
local FlaggedProjects = package.loaded.FlaggedProjects
local DeletedProjects = package.loaded.DeletedProjects
local Bookmarks = package.loaded.Bookmarks
local Collections = package.loaded.Collections
local Users = package.loaded.Users
local validation = package.loaded.validation

local is_likely_course_work = validation.is_likely_course_work

ProjectController = {
    run_query = function (self, query)
        -- query can hold a paginator or an SQL query
        if not self.params.page_number then self.params.page_number = 1 end
        local filters = ''
        if self.current_user and self.current_user:isadmin() then
          if self.params.filter_bookmarked == 'true' then
            filters = ' AND id IN (SELECT project_id FROM bookmarks)'
          elseif (self.params.filter_bookmarked == 'false') then -- could be nil
            filters = ' AND NOT id IN (SELECT project_id FROM bookmarks)'
          end
          if self.params.filter_order_by then
            self.params.order = self.params.filter_order_by
          end
        end

        local paginator = Projects:paginated(
                 query ..
                    (self.params.search_term and (db.interpolate_query(
                        ' AND (projectname ILIKE ? OR notes ILIKE ?)',
                        '%' .. self.params.search_term .. '%',
                        '%' .. self.params.search_term .. '%')
                    ) or '') ..
                    (filters or '') ..
                    ' ORDER BY ' ..
                        (self.params.order or 'firstpublished DESC'),
                {
                    per_page = self.params.items_per_page or 18,
                    fields = self.params.fields or '*'
                }
            )
        if self.req and (self.req.source == 'snap') then
            return jsonResponse({ projects = paginator:get_all() })
        else
            local items = {}
            if self.cached then
                items = cached_query(
                    { paginator._clause, self.params.page_number },
                    self.cache_category,
                    Projects,
                    function ()
                        local entries =
                            paginator:get_page(self.params.page_number)
                        disk:process_thumbnails(entries)
                        return entries
                    end
                )
            else
                items = paginator:get_page(self.params.page_number)
                disk:process_thumbnails(items)
            end
            if not self.ignore_page_count then
                if self.cached then
                    self.num_pages = cached_query(
                        { paginator._clause, 'count' },
                        self.cache_category .. '#count',
                        nil,
                        function ()
                            return paginator:num_pages()
                        end
                    )
                else
                    self.num_pages = paginator:num_pages()
                end
            end

            return items
        end
    end,
    fetch = capture_errors(function (self)
        self.cache_category = 'latest'
        return ProjectController.run_query(
            self,
            [[WHERE ispublished AND NOT EXISTS(
                SELECT 1 FROM deleted_users WHERE
                username = active_projects.username LIMIT 1)]]
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
        if users_match(self) and not self.params.show_public then
            return ProjectController.my_projects(self)
        else
            self.params.order = 'lastupdated DESC'
            return ProjectController.run_query(
                self,
                db.interpolate_query(
                    'WHERE ispublished AND username = ? ',
                    tostring(self.params.username)
                )
            )
        end
    end),
    followed_projects = capture_errors(function (self)
        self.params.order = 'lastupdated DESC'
        return ProjectController.run_query(
            self,
            db.interpolate_query([[
                WHERE ispublished AND username IN (
                    SELECT username FROM users WHERE id IN
                        (SELECT followed_id FROM followers
                            WHERE follower_id = ?)
                )
            ]], self.current_user.id)
        )
    end),
    all_recent_bookmarks = capture_errors(function (self)
        self.params.page_number = 1
        local projects = Projects:recently_bookmarked()
        self.num_pages = math.ceil(#projects /
            (self.items_per_page or 18))
        return projects
    end),
    bookmarked_projects = capture_errors(function (self)
        self.params.order = 'lastupdated DESC'
        return ProjectController.run_query(
            self,
            db.interpolate_query([[
                WHERE id IN (
                    SELECT project_id FROM bookmarks
                        WHERE bookmarker_id = ?
                )
            ]], self.current_user.id)
        )
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
                    (self.params.items_per_page or 18))
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
        uncache_category('latest')
        uncache_category('latest#count')
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
        uncache_category('latest')
        uncache_category('latest#count')
        return okResponse()
    end),
    unpublish = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_can_share(self, project)
        project:update({
            lastupdated = db.format_date(),
            ispublished = false
        })
        uncache_category('latest')
        uncache_category('latest#count')
        return okResponse()
    end),
    metadata = capture_errors(function (self)
        assert_users_match(self)

        if self.current_user:isbanned() and self.params.ispublished then
            yield_error(err.banned)
        end

        local project =
            Projects:find(
                tostring(self.params.username),
                tostring(self.params.projectname)
            )
        if not project then yield_error(err.nonexistent_project) end

        local shouldUpdateSharedDate =
            ((not project.lastshared and self.params.ispublic)
            or (self.params.ispublic and not project.ispublic))

        local result = project:update({
            lastupdated = db.format_date(),
            lastshared = shouldUpdateSharedDate and db.format_date() or nil,
            firstpublished =
                project.firstpublished or
                (self.params.ispublished and db.format_date()) or
                nil,
            ispublic = self.params.ispublic,
            ispublished = self.params.ispublished
        })

        if not result then yield_error({ msg = error, status = 422 }) end

        return okResponse(
            'project ' .. tostring(self.params.projectname) .. ' updated'
        )
    end),
    delete = capture_errors(function (self)
        local project =
            self.params.id and
                Projects:find({id = self.params.id })
            or
                Projects:find(
                    tostring(self.params.username),
                    tostring(self.params.projectname)
                )

        assert_can_delete(self, project)

        local username = project.username -- keep it for after deleting it

        if self.params.reason then
            send_mail(
                self.queried_user.email,
                mail_subjects.project_deleted .. tostring(project.projectname),
                mail_bodies.project_deleted .. self.current_user.role ..
                    '.</p><p>' .. self.params.reason .. '</p>')
        end

        -- Do not actually delete the project; flag it as deleted.
        if not (project:update({ deleted = db.format_date() })) then
            yield_error('Could not delete project ' ..
                tostring(self.params.projectname))
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
                message = 'Project ' .. tostring(project.projectname) ..
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
        -- Report the flagger for abusing the flagging system
        if self.params.report then
            flagger:update({ bad_flags = (flagger.bad_flags or 0) + 1 })
            if flagger.bad_flags >= 3 then
                -- TODO ban this user? probably, right?
            end
            send_mail(
                flagger.email,
                mail_subjects.bad_flag,
                mail_bodies.bad_flag(flagger, project)
            )
        end

        return okResponse()
    end),
    bookmark = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_project_exists(self, project)
        if not self.current_user then return okResponse() end

        local bookmark =
            Bookmarks:select(
                'WHERE project_id = ? AND bookmarker_id = ?',
                project.id,
                self.current_user.id
            )[1]

        if not bookmark then
          Bookmarks:create({
              bookmarker_id = self.current_user.id,
              project_id = project.id
          })
        end

        return okResponse()
    end),
    unbookmark = capture_errors(function (self)
        local project = Projects:find({ id = self.params.id })
        assert_project_exists(self, project)
        if not self.current_user then return okResponse() end

        local bookmark =
            Bookmarks:select(
                'WHERE project_id = ? AND bookmarker_id = ?',
                project.id,
                self.current_user.id
            )[1]

        if bookmark then
          db.delete(
              'bookmarks',
              'project_id = ? and bookmarker_id = ?',
              project.id,
              self.current_user.id
          );
        end

        return okResponse()
    end),
    mark_as_remix = capture_errors(function (self)
        if not users_match(self) then
            assert_min_role(self, 'moderator')
        end

        local original_project =
            Projects:find(
                tostring(self.params.original_username),
                tostring(self.params.original_projectname)
            )
        if original_project then
            Remixes:create({
                original_project_id = original_project.id,
                remixed_project_id = self.params.id,
                created = self.params.created
            })
        end

        return okResponse()
    end),
    xml = capture_errors(function (self)
        local project =
            self.params.id and
                Projects:find({ id = self.params.id })
            or
                Projects:find(
                    tostring(self.params.username),
                    tostring(self.params.projectname)
                )

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
            Projects:find(
                tostring(self.params.username),
                tostring(self.params.projectname)
            )

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
    versions = capture_errors(function (self)
        local project =
            Projects:find(
                tostring(self.params.username),
                tostring(self.params.projectname)
            )

        if not project then yield_error(err.nonexistent_project) end
        if not project.ispublic then
            assert_users_match(self, err.nonexistent_project)
        end

        -- seconds since last modification
        local query = db.select(
            'extract(epoch from age(now(), ?::timestamp))',
            project.lastupdated)[1]

        return jsonResponse({
            {
                lastupdated = query.date_part,
                thumbnail = disk:retrieve(project.id, 'thumbnail') or
                    disk:generate_thumbnail(project.id),
                notes = disk:parse_notes(project.id),
                delta = 0
            },
            disk:get_version_metadata(project.id, -1),
            disk:get_version_metadata(project.id, -2)
        })
    end),
    save = capture_errors(function (self)
        -- rate_limit(self)

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
            Projects:find(
                tostring(self.params.username),
                tostring(self.params.projectname)
            )

        if (project) then
            local shouldUpdateSharedDate =
                ((not project.lastshared and self.params.ispublic)
                or (self.params.ispublic and not project.ispublic))

            disk:backup_project(project.id)

            local likely_class_work = self.current_user:is_student() or
                is_likely_course_work(project.projectname)
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
                ispublished = self.params.ispublished or project.ispublished,
                likely_class_work = likely_class_work,
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
                tostring(self.params.username),
                tostring(self.params.projectname))
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

            local likely_class_work = self.current_user:is_student() or
                is_likely_course_work(self.params.projectname)
            Projects:create({
                projectname = tostring(self.params.projectname),
                username = tostring(self.params.username),
                created = db.format_date(),
                lastupdated = db.format_date(),
                lastshared = self.params.ispublic and
                    db.format_date() or nil,
                firstpublished = self.params.ispublished
                    and db.format_date() or nil,
                notes = body.notes,
                ispublic = self.params.ispublic or false,
                ispublished = self.params.ispublished or false,
                likely_class_work = likely_class_work,
            })
            project =
                Projects:find(
                    tostring(self.params.username),
                    tostring(self.params.projectname)
                )

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
                tostring(self.params.projectname))
        else
            return okResponse('project ' .. tostring(self.params.projectname) ..
                ' saved')
        end
    end)
}
