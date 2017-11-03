-- API module
-- ==========
--
-- See static/API for API description
--
-- written by Bernat Romagosa
--
-- Copyright (C) 2017 by Bernat Romagosa
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

local app = package.loaded.app
local db = package.loaded.db
local app_helpers = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local validate = package.loaded.validate
local bcrypt = package.loaded.bcrypt
local Model = package.loaded.Model
local util = package.loaded.util
local respond_to = package.loaded.respond_to
local json_params = package.loaded.json_params
local cached = package.loaded.cached
local Users = package.loaded.Users
local Projects = package.loaded.Projects

require 'disk'
require 'responses'
require 'validation'


-- API Endpoints
-- =============

app:match('init', '/init', respond_to({
    OPTIONS = cors_options,
    POST = function (self)
        if not self.session.username or
            (self.session.username and self.cookies.persist_session == 'false') then
            self.session.username = ''
        end
    end
}))

--[[
app:match('users', '/users', respond_to({
    -- Methods:     GET
    -- Description: Get a list of users. Returns an empty list if no parameters provided,
    --              except when the query issuer is an admin.
    -- Parameters:  matchtext, page, pagesize

    OPTIONS = cors_options,
    GET = function (self)
        -- TODO: security, filters and pagination
        return jsonResponse(Users:select({ fields = 'username' }))
    end
}))
]]--

app:match('current_user', '/users/c', respond_to({
    -- Methods:     GET
    -- Description: Get the currently logged user's username and credentials.

    OPTIONS = cors_options,
    GET = function (self)
        return jsonResponse({
            username = self.session.username,
            isadmin = self.session.isadmin })
    end
}))

app:match('user', '/users/:username', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get info about a user, or delete/add/update a user.

    OPTIONS = cors_options,
    GET = function (self)
        return jsonResponse(
            Users:select(
                'where username = ? limit 1',
                self.params.username,
                { fields = 'username, location, about, joined' }))
    end,

    DELETE = capture_errors(function (self)
        assert_all({'logged_in', 'admin'}, self)

        if not (user:delete()) then
            yield_error('Could not delete user ' .. self.params.username)
        else
            return okResponse('User ' .. self.params.username .. ' has been removed.')
        end
    end),

    POST = capture_errors(function (self)
        validate.assert_valid(self.params, {
            { 'username', exists = true, min_length = 4, max_length = 200 },
            { 'password', exists = true, min_length = 6 },
            { 'password_repeat', equals = self.params.password, 'passwords do not match' },
            { 'email', exists = true, min_length = 5 },
        })

        if Users:find(self.params.username) then
            yield_error('User ' .. self.params.username .. ' already exists');
        end

        Users:create({
            created = db.format_date(),
            username = self.params.username,
            password = bcrypt.digest(self.params.password, 11),
            email = self.params.email,
            isadmin = false,
            joined = db.format_date()
        })

        return okResponse('User ' .. self.params.username .. ' created')
    end)

}))

app:match('login', '/users/:username/login', respond_to({
    -- Methods:     POST
    -- Description: Logs a user into the system.
    -- Body:        password.

    OPTIONS = cors_options,
    POST = capture_errors(function (self)
        local user = Users:find(self.params.username)

        if not user then yield_error(err.nonexistent_user) end

        ngx.req.read_body()
        local password = ngx.req.get_body_data()

        if (bcrypt.verify(password, user.password)) then
            self.session.username = user.username
            self.session.isadmin = user.isadmin
            self.cookies.persist_session = self.params.persist
            return okResponse('User ' .. self.params.username .. ' logged in')
        else
            yield_error('invalid password')
        end
    end)
}))

app:match('logout', '/logout', respond_to({
    -- Methods:     POST
    -- Description: Logs out a user from the system.

    OPTIONS = cors_options,
    POST = capture_errors(function (self)
        self.session.username = ''
        self.cookies.persist_session = 'false'
        return okResponse('logged out')
    end)
}))


-- TODO refactor the following two, as they share most of the code

app:match('projects', '/projects', respond_to({
    -- Methods:     GET
    -- Description: Get a list of published projects.
    -- Parameters:  page, pagesize, matchtext, withthumbnail.

    OPTIONS = cors_options,
    GET = cached({
        exptime = 30, -- cache expires after 30 seconds
        function (self)
            local query = 'where ispublished'

            -- Apply where clauses
            if self.params.matchtext then
                query = query ..
                    db.interpolate_query(
                        ' and (projectname ~* ? or notes ~* ?)',
                        self.params.matchtext,
                        self.params.matchtext
                    )
            end

            local paginator = Projects:paginated(query .. ' order by created desc', { per_page = self.params.pagesize or 16 })
            local projects = self.params.page and paginator:get_page(self.params.page) or paginator:get_all()

            if self.params.withthumbnail == 'true' then
                for k, project in pairs(projects) do
                    project.thumbnail = retrieveFromDisk(project.id, 'thumbnail')
                end
            end

            return jsonResponse({
                pages = self.params.page and paginator:num_pages() or nil,
                projects = projects,
            })
        end
    })
}))

app:match('user_projects', '/projects/:username', respond_to({
    -- Methods:     GET
    -- Description: Get metadata for a project list by a user.
    --              Response will depend on parameters and query issuer permissions.
    -- Parameters:  ispublished, page, pagesize, matchtext, withthumbnail.

    OPTIONS = cors_options,
    GET = function (self)
        assert_user_exists(self)

        if self.session.username ~= self.params.username then
            local visitor = Users:find(self.session.username)
            if not visitor or not visitor.isadmin then
                self.params.ispublished = 'true'
            end
        end

        local query = db.interpolate_query('where username = ?', self.params.username)

        -- Apply where clauses
        if self.params.ispublished ~= nil then
            query = query ..
                db.interpolate_query(
                    ' and ispublished = ?',
                    self.params.ispublished == 'true'
                )
        end

        if self.params.matchtext then
            query = query ..
                db.interpolate_query(
                    ' and (projectname ~* ? or notes ~* ?)',
                    self.params.matchtext,
                    self.params.matchtext
                )
        end

        local paginator = Projects:paginated(query .. ' order by lastshared desc', { per_page = self.params.pagesize or 16 })
        local projects = self.params.page and paginator:get_page(self.params.page) or paginator:get_all()

        if self.params.withthumbnail == 'true' then
            for k, project in pairs(projects) do
                project.thumbnail = retrieveFromDisk(project.id, 'thumbnail')
            end
        end

        return jsonResponse({
            pages = self.params.page and paginator:num_pages() or nil,
            projects = projects,
        })
    end
}))

app:match('project', '/projects/:username/:projectname', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a particular project.
    --              Response will depend on query issuer permissions.
    -- Parameters:  ispublic, ispublished
    -- Body:        xml, notes, thumbnail

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        local project = Projects:find(self.params.username, self.params.projectname)

        if not project then yield_error(err.nonexistent_project) end
        if not project.ispublic or users_match() then assert_admin(self, err.not_public_project) end

        return rawResponse(retrieveFromDisk(project.id, 'project.xml'))
    end),
    DELETE = capture_errors(function (self)
        assert_all({'project_exists', 'user_exists'}, self)
        if not users_match() then assert_admin(self) end

        local project = Projects:find(self.params.username, self.params.projectname)
        deleteDirectory(project.id)
        if not (project:delete()) then
            yield_error('Could not delete user ' .. self.params.username)
        else
            return okResponse('User ' .. self.params.username .. ' has been removed.')
        end
    end),
    POST = capture_errors(function (self)
        validate.assert_valid(self.params, {
            { 'projectname', exists = true },
            { 'username', exists = true }
        })

        assert_all({'user_exists', 'users_match'}, self)

        -- Read request body and parse it into JSON
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        local body = body_data and util.from_json(body_data) or nil

        if (not body.xml) then
            yield_error('Empty project contents')
        end

        local project = Projects:find(self.params.username, self.params.projectname)

        if (project) then
            local shouldUpdateSharedDate =
                ((not project.lastshared and self.params.ispublished)
                or (self.params.ispublished and not project.ispublished))

            project:update({
                lastupdated = db.format_date(),
                lastshared = shouldUpdateSharedDate and db.format_date() or nil,
                notes = body.notes,
                ispublic = self.params.ispublic or project.ispublic,
                ispublished = self.params.ispublished or project.ispublic
            })
        else
            Projects:create({
                projectname = self.params.projectname,
                username = self.params.username,
                created = db.format_date(),
                lastupdated = db.format_date(),
                lastshared = self.params.ispublished and db.format_date() or nil,
                notes = body.notes,
                ispublic = self.params.ispublic or false,
                ispublished = self.params.ispublished or false
            })
            project = Projects:find(self.params.username, self.params.projectname)
        end

        saveToDisk(project.id, 'project.xml', body.xml)
        saveToDisk(project.id, 'thumbnail', body.thumbnail)
        saveToDisk(project.id, 'media.xml', body.media)

        if not (retrieveFromDisk(project.id, 'project.xml')
            and retrieveFromDisk(project.id, 'thumbnail')
            and retrieveFromDisk(project.id, 'media.xml')) then
            project:delete()
            yield_error('Could not save project ' .. self.params.projectname)
        else
            return okResponse('project ' .. self.params.projectname .. ' saved')
        end

    end)
}))

app:match('project_meta', '/projects/:username/:projectname/metadata', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/add/update a project metadata.
    -- Parameters:  projectname, ispublic, ispublished, lastupdated, lastshared.
    -- Body:        notes, projectname

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        local project = Projects:find(self.params.username, self.params.projectname)

        if not project then yield_error(err.nonexistent_project) end
        if not project.ispublic then assert_users_match(self, err.not_public_project) end

        return jsonResponse(project)
    end),
    POST = capture_errors(function (self)
        assert_user_exists(self)
        if not users_match(self) then assert_admin(self) end

        local project = Projects:find(self.params.username, self.params.projectname)
        if not project then yield_error(err.nonexistent_project) end

        local shouldUpdateSharedDate =
            ((not project.lastshared and self.params.ispublished)
            or (self.params.ispublished and not project.ispublished))

        -- Read request body and parse it into JSON
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        local body = body_data and util.from_json(body_data) or nil
        local new_name = body and body.projectname or nil
        local new_notes = body and body.notes or nil

        project:update({
            projectname = new_name or project.projectname,
            lastupdated = db.format_date(),
            lastshared = shouldUpdateSharedDate and db.format_date() or nil,
            notes = new_notes or project.notes,
            ispublic = self.params.ispublic or project.ispublic,
            ispublished = self.params.ispublished or project.ispublished
        })

        return okResponse('project ' .. self.params.projectname .. ' updated')
    end)
}))

app:match('project_thumb', '/projects/:username/:projectname/thumbnail', respond_to({
    -- Methods:     GET
    -- Description: Get a project thumbnail.

    OPTIONS = cors_options,
    GET = capture_errors(
    cached({
        exptime = 30, -- cache expires after 30 seconds
        function (self)
            local project = Projects:find(self.params.username, self.params.projectname)
            if not project then yield_error(err.nonexistent_project) end

            if self.params.username ~= self.session.username
                and not project.ispublic then
                yield_error(err.auth)
            end

            return rawResponse(retrieveFromDisk(project.id, 'thumbnail'))
        end
    }))
}))
