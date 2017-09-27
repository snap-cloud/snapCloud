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

-- Response utils

jsonResponse = function (json)
    return {
        layout = false, 
        status = 200, 
        readyState = 4, 
        json = json or {}
    }
end

okResponse = function (message)
    return jsonResponse({ message = message })
end

cors_options = function (self)
    self.res.headers['access-control-allow-headers'] = 'Content-Type'
    self.res.headers['access-control-allow-method'] = 'POST, GET, DELETE, OPTIONS'
    return { status = 200, layout = false }
end

err = {
    notLoggedIn = 'you are not logged in',
    auth = 'you do not have permission to perform this action',
    nonexistentUser = 'no user with this username exists',
    nonexistentProject = 'this project does not exist, or you do not have permissions to access it'
}

-- Database abstractions

local Users = Model:extend('users', {
    primary_key = { 'username' }
})

local Projects = Model:extend('projects', {
    primary_key = { 'username', 'projectname' }
})

-- Before filter

app:before_filter(function (self)
    -- unescape all parameters
    for k,v in pairs(self.params) do
        self.params[k] = util.unescape(v)
    end

    -- Set Access Control header
    self.res.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'
    self.res.headers['Access-Control-Allow-Credentials'] = 'true'

    if (not self.session.username) then
        self.session.username = ''
    end
end)

-- API Endpoints
-- =============

app:get('/users', function (self)

    -- Methods:     GET
    -- Description: Get a list of users. Returns an empty list if no parameters provided,
    --              except when the query issuer is an admin.
    -- Parameters:  matchtext, page, pagesize

    return jsonResponse(Users:select({ fields = 'username' }))
end)

app:get('current_user', '/users/c', function (self)

    -- Methods:     GET
    -- Description: Get the currently logged user's username.
    -- Parameters:  password

    return jsonResponse(self.session.username)
end)

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
            { 'username', exists = true, min_length = 2, max_length = 200 },
            { 'password', exists = true, min_length = 3 },
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

app:match('projects', '/projects', respond_to({

    -- Methods:     GET
    -- Description: Get a list of published projects. Returns an empty list if no parameters
    --              provided, except when the query issuer is an admin.
    -- Parameters:  updatedrange, publishedrange, page, pagesize, matchtext.

    OPTIONS = cors_options,
    GET = function (self)
    end
}))

app:match('user_projects', '/projects/:username', respond_to({

    -- Methods:     GET
    -- Description: Get all projects by a user.
    --              Response will depend on parameters and query issuer permissions.
    -- Parameters:  ispublished, publishedrange, updatedrange, page, pagesize, matchtext

    OPTIONS = cors_options,
    GET = function (self)
    end
}))

app:match('project', '/projects/:username/:projectname', respond_to({

    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a particular project.
    --              Response will depend on query issuer permissions.

    OPTIONS = cors_options,
    GET = function (self)
    end
}))

app:match('project_meta', '/users/:username/:projectname/metadata', respond_to({

    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a project metadata.
    -- Parameters:  projectname, ispublic, ispublished, notes, lastupdated, lastshared.

    OPTIONS = cors_options,
    GET = function (self)
    end
}))

app:match('project_thumb', '/users/:username/:projectname/thumbnail/:size', respond_to({

    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a big/small project thumbnail.

    OPTIONS = cors_options,
    GET = function (self)
    end
}))
