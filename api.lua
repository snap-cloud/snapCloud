-- API module
-- ==========
-- See static/API for API description

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

require 'disk'
require 'responses'

-- Database abstractions

local Users = Model:extend('users', {
    primary_key = { 'username' }
})

local Projects = Model:extend('projects', {
    primary_key = { 'username', 'projectname' }
})

-- API Endpoints
-- =============

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

app:match('current_user', '/users/c', respond_to({

    -- Methods:     GET
    -- Description: Get the currently logged user's username.

    OPTIONS = cors_options,
    GET = function (self)
        return jsonResponse({ username = self.session.username })
    end
}))

app:match('user', '/users/:username', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get info about a user, or delete/add/update a user.

    OPTIONS = cors_options,
    GET = function (self)
        return jsonResponse(
            Users:select(
                'where username = ?',
                self.params.username,
                { fields = 'username, location, about, joined' })[1])
    end,

    DELETE = capture_errors(function (self)
        local visitor = Users:find(self.session.username)
        local user = Users:find(self.params.username)

        if not (visitor and visitor.isadmin) then
            yield_error(visitor and err.auth or err.notLoggedIn)
        else
            if not (user:delete()) then
                yield_error('Could not delete user ' .. self.params.username)
            else
                return okResponse('User ' .. self.params.username .. ' has been removed.')
            end
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
    -- Parameters:  password

    OPTIONS = cors_options,
    POST = capture_errors(function (self)
        local user = Users:find(self.params.username)

        if (not user) then
            yield_error('invalid username')
        elseif (bcrypt.verify(self.params.password, user.password)) then
            self.session.username = user.username
            return okResponse('User ' .. self.params.username .. ' logged in')
        else
            yield_error('invalid password')
        end
    end)
}))

app:match('logout', '/users/:username/logout', respond_to({
    -- Methods:     POST
    -- Description: Logs out a user from the system.

    OPTIONS = cors_options,
    POST = capture_errors(function (self)
        if (self.session.username ~= self.params.username) then
            -- Someone is trying to log someone else out
            yield_error(err.auth)
        else
            self.session.username = ''
            return okResponse('user ' .. self.params.username .. ' logged out')
        end
    end)
}))


app:match('projects', '/projects', respond_to({
    -- Methods:     GET
    -- Description: Get a list of published projects. Returns an empty list if no parameters
    --              provided, except when the query issuer is an admin.
    -- Parameters:  updatedrange, publishedrange, page, pagesize, matchtext.

    OPTIONS = cors_options,
    GET = function (self)
        -- TODO
    end
}))

app:match('user_projects', '/projects/:username', respond_to({
    -- Methods:     GET
    -- Description: Get all projects by a user.
    --              Response will depend on parameters and query issuer permissions.
    -- Parameters:  ispublished, publishedrange, updatedrange, page, pagesize, matchtext

    OPTIONS = cors_options,
    GET = function (self)
        -- TODO
    end
}))

app:match('project', '/projects/:username/:projectname', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a particular project.
    --              Response will depend on query issuer permissions.
    -- Parameters:  ispublic, ispublished, notes, thumbnail

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        local project = Projects:find(self.params.username, self.params.projectname)
        if not project then
            yield_error(err.nonexistentProject)
        end

        if (not Users:find(self.params.username)) then
            yield_error(err.nonexistentUser)
        end

        if (self.params.username ~= self.session.username) then
            yield_error(err.auth)
        end

        project.contents = retrieveFromDisk(project.id, 'project.xml')
        return jsonResponse(project)
    end),
    DELETE = capture_errors(function (self)
        -- TODO
    end),
    POST = capture_errors(function (self)
        validate.assert_valid(self.params, {
            { 'projectname', exists = true },
            { 'username', exists = true },
            { 'thumbnail', exists = true }
        })

        if (not Users:find(self.params.username)) then
            yield_error(err.nonexistentUser)
        end

        if (self.params.username ~= self.session.username) then
            yield_error(err.auth)
        end

        ngx.req.read_body()
        self.params.contents = ngx.req.get_body_data()

        if (not self.params.contents) then
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
                notes = self.params.notes,
                ispublic = self.params.ispublic,
                ispublished = self.params.ispublished
            })
        else
            Projects:create({
                projectname = self.params.projectname,
                username = self.params.username,
                lastupdated = db.format_date(),
                lastshared = self.params.ispublished and db.format_date() or nil,
                notes = self.params.notes,
                ispublic = self.params.ispublic,
                ispublished = self.params.ispublished
            })
            project = Projects:find(self.params.username, self.params.projectname)
        end

        saveToDisk(project.id, 'project.xml', self.params.contents)
        saveToDisk(project.id, 'thumbnail', self.params.thumbnail)

        if not (retrieveFromDisk(project.id, 'project.xml') and retrieveFromDisk(project.id, 'thumbnail')) then
            project:delete()
            yield_error('Could not save project ' .. self.params.projectname)
        else
            return okResponse('project ' .. self.params.projectname .. ' saved')
        end

    end)
}))

app:match('project_meta', '/projects/:username/:projectname/metadata', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a project metadata.
    -- Parameters:  projectname, ispublic, ispublished, notes, lastupdated, lastshared.

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO
    end),
    DELETE = capture_errors(function (self)
        -- TODO
    end),
    POST = capture_errors(function (self)
        -- TODO
    end)
}))

app:match('project_thumb', '/projects/:username/:projectname/thumbnail', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a project thumbnail.

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        local project = Projects:find(self.params.username, self.params.projectname)
        if not project then
            yield_error(err.nonexistentProject)
        elseif self.params.username ~= self.session.username
            and not project.isPublic then
            yield_error(err.auth)
        else
            return rawResponse(retrieveFromDisk(project.id, 'thumbnail'))
        end
    end),
    DELETE = capture_errors(function (self)
        -- TODO
    end),
    POST = capture_errors(function (self)
        -- TODO
    end)
}))
