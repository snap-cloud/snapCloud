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
local capture_errors = package.loaded.capture_errors

local Model = package.loaded.Model
local respond_to = package.loaded.respond_to

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
    POST = UserController.POST.user,
    DELETE = UserController.DELETE.user
}))

app:match(api_route('new_password', '/users/:username/newpassword', {
    -- Methods:     POST
    -- Description: Sets a new password for a user. All passwords should travel pre-hashed
    --              with SHA512.
    -- Parameters:  oldpassword, password_repeat, newpassword

    POST = UserController.POST.new_password
}))

app:match(api_route('resend_verification', '/users/:username/resendverification', {
    -- Methods:     POST
    -- Description: Resends user verification email.

    POST = UserController.POST.resend_verification
}))

app:match(api_route('password_reset', '/users/:username/password_reset(/:token)', {
    -- Methods:     GET, POST
    -- Description: Handles password reset requests.
    --              The route name should match the database token purpose.
    -- @see validation.create_token

    GET = UserController.GET.password_reset,
    POST = UserController.POST.password_reset
}))

app:match(api_route('login', '/users/:username/login', {
    -- Methods:     POST
    -- Description: Logs a user into the system.
    -- Body:        password

    POST = UserController.POST.login
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

    POST = UserController.POST.logout
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

    GET = ProjectController.GET.project,
    POST = ProjectController.POST.project,
    DELETE = ProjectController.DELETE.project
}))

app:match(api_route('project_meta', '/projects/:username/:projectname/metadata', {
    -- Methods:     GET, DELETE, POST
    -- Description: Get/add/update a project metadata.
    -- Parameters:  projectname, ispublic, ispublished, lastupdated, lastshared
    -- Body:        notes, projectname

    GET = ProjectController.GET.project_meta,
    POST = ProjectController.POST.project_meta
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
