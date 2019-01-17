-- API module
-- ==========
--
-- See static/API for API description
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

local app = package.loaded.app
local db = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local validate = package.loaded.validate
local Model = package.loaded.Model
local util = package.loaded.util
local respond_to = package.loaded.respond_to
local json_params = package.loaded.json_params
local cached = package.loaded.cached
local Users = package.loaded.Users
local Projects = package.loaded.Projects
local DeletedProjects = package.loaded.DeletedProjects
local Tokens = package.loaded.Tokens
local Remixes = package.loaded.Remixes

local cjson = require('cjson')

require 'disk'
require 'responses'
require 'validation'
require 'passwords'
require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'

function wrap_capture_errors(tbl)
    if tbl.GET then tbl.GET = capture_errors(tbl.GET) end
    if tbl.POST then tbl.POST = capture_errors(tbl.POST) end
    if tbl.DELETE then tbl.DELETE = capture_errors(tbl.DELETE) end
    -- if tbl.PUT then tbl.PUT = capture_errors(tbl.PUT) end
end

-- Wraps all API endpoints in standard behavior.

local function api_route(name, path, tbl)
    tbl.OPTIONS = cors_options
    wrap_capture_errors(tbl)
    return name, '(/api/v1)' .. path, respond_to(tbl)
end


-- API Endpoints
-- =============

app:match(api_route('init', '/init', {
    POST = function (self)
        if not self.session.username or
            (self.session.username and self.cookies.persist_session == 'false') then
            self.session.username = ''
        end
    end
}))


-- Users
-- =====

app:match(api_route('current_user', '/users/c', {
    -- Methods:     GET
    -- Description: Get the currently logged user's username and credentials.
    GET = UserController.GET.current_user
}))

app:match(api_route('user_list', '/users', {
    -- Methods:     GET
    -- Description: If requesting user is an admin, get a paginated list of all users
    --              with username or email matching matchtext, if provided.
    -- Parameters:  matchtext, page, pagesize

    GET = UserController.GET.user_list
}))

app:match(api_route('user', '/users/:username', {
    -- Methods:     GET, DELETE, POST
    -- Description: Get info about a user, or delete/add/update a user. All passwords should
    --              travel pre-hashed with SHA512.

    -- Parameters:  username, password, password_repeat, email

    GET = UserController.GET.user,

    DELETE = function (self)
        assert_user_exists(self)

        if not users_match(self) then assert_admin(self) end

        if not (self.queried_user:delete()) then
            yield_error('Could not delete user ' .. self.params.username)
        else
            return okResponse('User ' .. self.params.username .. ' has been removed.')
        end
    end,

    POST = function (self)
        if (self.current_user) then
            if not users_match(self) then assert_admin(self) end
            -- user is updating profile, or an admin is updating somebody else's profile
            self.queried_user:update({
                -- we only support changing a user's email at the moment, but we could use
                -- this method to update their permissions in the future too
                email = self.params.email or self.queried_user.email
            })
            return okResponse('Profile for user ' .. self.queried_user.username .. ' updated')
        else
            -- new user
            validate.assert_valid(self.params, {
                { 'username', exists = true, min_length = 4, max_length = 200 },
                { 'password', exists = true, min_length = 6 },
                { 'password_repeat', equals = self.params.password, 'passwords do not match' },
                { 'email', exists = true, min_length = 5 },
            })

            if self.queried_user then
                yield_error('User ' .. self.queried_user.username .. ' already exists');
            end

            local salt = secure_salt()
            Users:create({
                created = db.format_date(),
                username = self.params.username,
                salt = salt,
                password = hash_password(self.params.password, salt), -- see validation.lua >> hash_password
                email = self.params.email,
                verified = false,
                role = 'standard'
            })

            -- Create a verify_user-type token and send an email to the user asking to
            -- verify the account.
            -- We check these on login.
            create_token(self, 'verify_user', self.params.username, self.params.email)
            return okResponse(
            'User ' .. self.params.username ..
            ' created.\nPlease check your email and validate your\naccount within the next 3 days.')
        end
    end

}))

app:match(api_route('new_password', '/users/:username/newpassword', {
    -- Methods:     POST
    -- Description: Sets a new password for a user. All passwords should travel pre-hashed
    --              with SHA512.
    -- Parameters:  oldpassword, password_repeat, newpassword

    POST = function (self)
        assert_all({'user_exists', 'users_match'}, self)

        if self.queried_user.password ~= hash_password(self.params.oldpassword, self.queried_user.salt) then
            yield_error('wrong password')
        end

        validate.assert_valid(self.params, {
            { 'password_repeat', equals = self.params.newpassword, 'passwords do not match' },
            { 'newpassword', exists = true, min_length = 6 }
        })

        self.queried_user:update({
            password = hash_password(self.params.newpassword, self.queried_user.salt)
        })

        return okResponse('Password updated')
    end
}))

app:match(api_route('resend_verification', '/users/:username/resendverification', {
    -- Methods:     POST
    -- Description: Resends user verification email.

    POST = function (self)
        assert_user_exists(self)
        if self.queried_user.verified then
            return okResponse('User ' .. self.queried_user.username .. ' is already verified.\nThere is no need for you to do anything.\n')
        end
        create_token(self, 'verify_user', self.queried_user.username, self.queried_user.email)
        return okResponse(
            'Verification email for ' .. self.queried_user.username ..
            ' sent.\nPlease check your email and validate your\n' ..
            'account within the next 3 days.')
    end
}))

app:match(api_route('password_reset', '/users/:username/password_reset(/:token)', {
    -- Methods:     GET, POST
    -- Description: Handles password reset requests.
    --              The route name should match the database token purpose.
    -- @see validation.create_token

    GET = UserController.GET.password_reset,

    POST = function (self)
        assert_user_exists(self)
        create_token(self, 'password_reset', self.params.username, self.queried_user.email)
        return okResponse('Password reset request sent.\nPlease check your email.')
    end
}))

app:match(api_route('login', '/users/:username/login', {
    -- Methods:     POST
    -- Description: Logs a user into the system.
    -- Body:        password

    POST = function (self)
        assert_user_exists(self)

        ngx.req.read_body()
        local password = ngx.req.get_body_data()

        if (hash_password(password, self.queried_user.salt) == self.queried_user.password) then
            if not self.queried_user.verified then
                -- Check whether verification token is still unused and valid
                local token =
                    Tokens:find({
                        username = self.queried_user.username,
                        purpose = 'verify_user'
                    })
                if token then
                    local query = db.select("date_part('day', now() - ?::timestamp)", token.created)[1]
                    if query.date_part > 3 then
                        token:delete()
                        yield_error(err.nonvalidated_user)
                    else
                        self.queried_user.days_left = 3 - query.date_part
                    end
                else
                    yield_error(err.nonvalidated_user)
                end
            end
            self.session.username = self.queried_user.username
            self.session.role = self.queried_user.role
            self.session.verified = self.queried_user.verified
            self.cookies.persist_session = self.params.persist
            if self.queried_user.verified then
                return okResponse('User ' .. self.queried_user.username .. ' logged in')
            else
                return jsonResponse({ days_left = self.queried_user.days_left })
            end
        else
            -- Admins can log in as other people
            assert_admin(self, 'wrong password')
            local previous_username = self.current_user.username
            self.session.username = self.queried_user.username
            self.session.role = self.queried_user.role
            self.session.verified = self.queried_user.verified
            self.cookies.persist_session = 'false'
            return okResponse('User ' .. previous_username .. ' now logged in as ' .. self.queried_user.username)
        end
    end
}))

app:match(api_route('verify_user', '/users/:username/verify_user/:token', {
    -- Methods:     GET
    -- Description: Verifies a user's email by means of a token, or removes
    --              that token if it has expired.
    --              If requesting user is an admin, verifies the user and removes
    --              the token. Token should equal '0' for admins.
    --              Returns a success message if the user is already verified.
    --              The route name should match the database token purpose.
    -- @see validation.create_token

    GET = UserController.GET.verify_user
}))

app:match(api_route('logout', '/logout', {
    -- Methods:     POST
    -- Description: Logs out the current user from the system.

    POST = function (self)
        self.session.username = ''
        self.cookies.persist_session = 'false'
        return okResponse('logged out')
    end
}))


-- Projects
-- ========

app:match(api_route('projects', '/projects', {
    -- Methods:     GET
    -- Description: Get a list of published projects.
    -- Parameters:  page, pagesize, matchtext, withthumbnail

    GET = ProjectController.GET.projects
}))

app:match(api_route('user_projects', '/projects/:username', {
    -- Methods:     GET
    -- Description: Get metadata for a project list by a user.
    --              Response will depend on parameters and query issuer permissions.
    -- Parameters:  ispublished, page, pagesize, matchtext, withthumbnail, updatingnotes

    GET = ProjectController.GET.user_projects
}))

app:match(api_route('project', '/projects/:username/:projectname', {
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a particular project.
    --              Response will depend on query issuer permissions.
    -- Parameters:  delta, ispublic, ispublished
    -- Body:        xml, notes, thumbnail

    GET = ProjectController.GET.user,
    DELETE = function (self)
        assert_all({'project_exists', 'user_exists'}, self)
        if not users_match(self) then assert_admin(self) end

        local project = Projects:find(self.params.username, self.params.projectname)
        --[[
        local id = project.id

        -- Check out whether this project was a remix of some other project, then delete the remix
        local remix = Remixes:select('where remixed_project_id = ?', id)[1]
        if remix then remix:delete() end

        -- Check out whether this project has been remixed by other projects, then orphan these remixes
        local query = db.query('update remixes set original_project_id = null where original_project_id = ?', id);

        if not (project:delete()) then
            yield_error('Could not delete project ' .. self.params.projectname)
        else
            delete_directory(id)
            return okResponse('Project ' .. self.params.projectname .. ' has been removed.')
        end
        ]]--

        -- Do not actually delete the project; flag it as deleted.

        if not (project:update({ deleted = db.format_date() })) then
            yield_error('Could not delete project ' .. self.params.projectname)
        else
            return okResponse('Project ' .. self.params.projectname .. ' has been removed.')
        end
    end,
    POST = function (self)
        validate.assert_valid(self.params, {
            { 'projectname', exists = true },
            { 'username', exists = true }
        })

        assert_all({assert_user_exists, assert_users_match}, self)

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
                ((not project.lastshared and self.params.ispublic)
                or (self.params.ispublic and not project.ispublic))

            backup_project(project.id)

            project:update({
                lastupdated = db.format_date(),
                lastshared = shouldUpdateSharedDate and db.format_date() or nil,
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

            -- A project flagged as "deleted" with the same name may exist in the DB.
            -- We need to check for that and delete it for real this time
            local deleted_project = DeletedProjects:find(self.params.username, self.params.projectname)
            if deleted_project then deleted_project:delete() end

            Projects:create({
                projectname = self.params.projectname,
                username = self.params.username,
                created = db.format_date(),
                lastupdated = db.format_date(),
                lastshared = self.params.ispublic and db.format_date() or nil,
                firstpublished = self.params.ispublished and db.format_date() or nil,
                notes = body.notes,
                ispublic = self.params.ispublic or false,
                ispublished = self.params.ispublished or false
            })
            project = Projects:find(self.params.username, self.params.projectname)

            if (body.remixID and body.remixID ~= cjson.null) then
                -- user is remixing a project
                Remixes:create({
                    original_project_id = body.remixID,
                    remixed_project_id = project.id,
                    created = db.format_date()
                })
            end
        end

        save_to_disk(project.id, 'project.xml', body.xml)
        save_to_disk(project.id, 'thumbnail', body.thumbnail)
        save_to_disk(project.id, 'media.xml', body.media)

        if not (retrieve_from_disk(project.id, 'project.xml')
            and retrieve_from_disk(project.id, 'thumbnail')
            and retrieve_from_disk(project.id, 'media.xml')) then
            yield_error('Could not save project ' .. self.params.projectname)
        else
            return okResponse('project ' .. self.params.projectname .. ' saved')
        end
    end
}))

app:match(api_route('project_meta', '/projects/:username/:projectname/metadata', {
    -- Methods:     GET, DELETE, POST
    -- Description: Get/add/update a project metadata.
    -- Parameters:  projectname, ispublic, ispublished, lastupdated, lastshared
    -- Body:        notes, projectname

    GET = ProjectController.GET.project_meta,
    POST = function (self)
        if not users_match(self) then assert_admin(self) end

        local project = Projects:find(self.params.username, self.params.projectname)
        if not project then yield_error(err.nonexistent_project) end

        local shouldUpdateSharedDate =
            ((not project.lastshared and self.params.ispublic)
            or (self.params.ispublic and not project.ispublic))

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
            firstpublished =
                project.firstpublished or
                (self.params.ispublished and db.format_date()) or
                nil,
            notes = new_notes or project.notes,
            ispublic = self.params.ispublic or project.ispublic,
            ispublished = self.params.ispublished or project.ispublished
        })

        return okResponse('project ' .. self.params.projectname .. ' updated')
    end
}))

app:match(api_route('project_versions', '/projects/:username/:projectname/versions', {
    -- Methods:     GET
    -- Description: Get info about backed up project versions.
    -- Parameters:
    -- Body:        versions

    GET = ProjectController.GET.project_versions
}))

app:match(api_route('project_remixes',
                    '/projects/:username/:projectname/remixes', {
    -- Methods:     GET
    -- Description: Get a list of all published remixes from a project.
    -- Parameters:  page, pagesize
    -- Body:

    GET = ProjectController.GET.project_remixes
}))

app:match(api_route('project_thumbnail',
                    '/projects/:username/:projectname/thumbnail', {
    -- Methods:     GET
    -- Description: Get a project thumbnail.

    GET = ProjectController.GET.project_thumbnail
}))


-- Collections
-- ===========

app:match(api_route('collections_list', '/collections', {
    -- Methods:     GET
    -- Description: If requesting user is an admin, get a paginated list of all
    --              collections with name matching matchtext, if provided.
    --              Returns public collections
    -- Parameters:  matchtext, page, pagesize

    GET = CollectionController.GET.collections_list
}))

app:match(api_route('user_collections', '/users/:username/collections', {
    -- Methods:     GET
    -- Description: Get a paginated list of all a particular user's collections
    --              with name matching matchtext, if provided.
    --              Returns only public collections, if another user.
    -- Parameters:  GET: username, matchtext, page, pagesize

    GET = CollectionController.GET.user_collections
}))

app:match(api_route('collection',
          '/users/:username/collections/:collection_slug', {
    -- Methods:     GET, POST, DELETE
    -- Description: Get the info about a collection.
    --              Create and a delete a collection.
    -- Parameters:  username, collection_name, ...

    GET = CollectionController.GET.collection,
    POST = CollectionController.POST.collection,
    DELETE = CollectionController.DELETE.collection
}))

app:match(api_route('collection_memberships',
          '/users/:username/collections/:collection_slug/items(/:item_id)', {
    -- Methods:     GET, DELETE
    -- Description: Get a paginated list of all items in a collection.
    --              Add or remove items from the collection.
    -- Parameters:  username, collection_slug

    GET = CollectionController.GET.collection_memberships,
    POST = CollectionController.POST.collection_memberships,
    DELETE = CollectionController.DELETE.collection_memberships,
}))
