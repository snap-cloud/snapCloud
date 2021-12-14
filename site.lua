-- Community site routes
-- =====================
--
-- Routes for all community website pages. We're in the process of starting to
-- transition the whole site to Lua.
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

local app = package.loaded.app
local util = package.loaded.util
local capture_errors = package.loaded.capture_errors
local cached = package.loaded.cached
local respond_to = package.loaded.respond_to

local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Remixes = package.loaded.Remixes
local Collections = package.loaded.Collections
local FlaggedProjects = package.loaded.FlaggedProjects
local db = package.loaded.db

require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'
require 'controllers.counter'

-- All component actions and queries are separated into the site controller
--require 'controllers.site'

app:enable('etlua')
app.layout = require 'views.layout'

local views = {
    -- Static pages
    'about', 'bjc', 'coc', 'contact', 'credits', 'dmca', 'extensions',
    'materials', 'mirrors', 'offline', 'partners', 'privacy', 'requirements',
    'research', 'snapinator', 'snapp', 'source', 'tos',

    -- Simple pages
    'blog', 'change_email', 'change_password', 'delete_user', 'forgot_password',
    'forgot_username', 'sign_up',

    -- Simple, component-based pages
    'explore', 'my_projects', 'my_collections'
}

for _, view in pairs(views) do
    app:get('/' .. view, capture_errors(function (self)
        return { render = view }
    end))
end

app:get('/embed', capture_errors(function (self)
    -- Backwards compatibility with previous URL params
    self.project = Projects:find(
        self.params.user or self.params.username,
        self.params.project or self.params.projectname
    )
    return { render = 'embed', layout = false }
end))

-- Pages that use AJAX-enabled components

local index = capture_errors(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'index' }
end)

app:get('/', index)
app:get('/index', index)

app:get('/admin', capture_errors(function (self)
    assert_min_role(self, 'reviewer')
    return { render = 'admin' }
end))

app:get('/user', capture_errors(function (self)
    self.username = self.queried_user.username
    self.user_id = self.queried_user.id
    return { render = 'user' }
end))

app:get('/project', capture_errors(function (self)
    -- Backwards compatibility with previous URL params
    self.project = Projects:find(
        self.params.user or self.params.username,
        self.params.project or self.params.projectname
    )
    -- check whether this is a remix of another project
    local remix =
        Remixes:select('WHERE remixed_project_id = ?', self.project.id)
    if remix[1] then
        self.remixed_from =
            Projects:select('WHERE id = ?', remix[1].original_project_id)[1]
    end
    if self.current_user then
        self.admin_controls = self.current_user:has_min_role('moderator')
        self.reviewer_controls = self.current_user:has_min_role('reviewer')
    end
    return { render = 'project' }
end))

app:get('/examples', capture_errors(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'examples' }
end))

app:get('/collection', capture_errors(function (self)
    local creator = Users:find({ username = self.params.username })
    self.collection =
        Collections:find(creator.id, self.params.collection)
    assert_can_view_collection(self, self.collection)
    self.collection.creator = creator

    if self.collection.thumbnail_id then
        self.collection.thumbnail =
            package.loaded.disk:retrieve_thumbnail(
                self.collection.thumbnail_id)
    end

    if self.collection.editor_ids then
        self.collection.editors = Users:find_all(
        self.collection.editor_ids,
        { fields = 'username, id' })
    end

    return { render = 'collection' }
end))

app:get('/search', capture_errors(function (self)
    self.reviewer_controls =
        self.current_user and self.current_user:has_min_role('reviewer')
    return { render = 'search' }
end))

-- Administration and data management pages

app:get('/profile', capture_errors(function (self)
    self.user = self.current_user
    return { render = 'profile' }
end))

app:get('/flags', capture_errors(function (self)
    assert_min_role(self, 'reviewer')
    return { render = 'flags' }
end))

app:get('/user_admin', capture_errors(function (self)
    assert_min_role(self, 'moderator')
    return { render = 'user_admin' }
end))

app:get('/login', capture_errors(function (self)
    return { render = 'login' }
end))

--[[
-- TEST COUNTER COMPONENT
app:get('/counter', capture_errors(function (self)
    if self.session.value == nil then self.session.value = 0 end
    self.component = { template = 'counter', controller = 'counter' }
    return { render = 'component' }
end))
--]]

-- controller calls

local controller_dispatch = function (self)
    -- 'user' →  'UserController'
    local controller_name =
        self.params.controller:gsub("^%l", string.upper) .. 'Controller'
    local method = _G[controller_name][self.params.selector]
    if method then
        return method(self)
    else
        error(
            'method ' .. self.params.selector ..
            ' not found in controller ' .. controller_name
        )
    end
end

app:post(
    '/call_lua/:controller/:selector',
    capture_errors(function (self)
        -- run the action associated to this particular component and selector,
        -- from the specified controller
        if self.params.data then
            self.params.data = package.loaded.util.from_json(self.params.data)
        end
        return {
            controller_dispatch(self),
            content_type = 'text/plain',
            layout = false
        }
    end)
)

-- component updater
app:post(
    '/update_component/:component_id/:template/:controller/:selector',
    capture_errors(cached(function (self)
        -- run the action associated to this particular component and selector,
        -- from the actions table

        self.params.data = package.loaded.util.from_json(self.params.data)

        self.component = {
            id = self.params.component_id,
            controller = self.params.controller,
            fetch_selector = self.params.data.fetch_selector or 'fetch'
        }
        -- ignore return value, as we'll just re-render the component
        controller_dispatch(self)

        self.data = self.params.data

        return { 
            render = self.params.template,
            layout = false,
        }
    end))
)


