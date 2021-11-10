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
local capture_errors = package.loaded.capture_errors
local respond_to = package.loaded.respond_to

local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Remixes = package.loaded.Remixes
local Collections = package.loaded.Collections
local FlaggedProjects = package.loaded.FlaggedProjects
local db = package.loaded.db
local component = package.loaded.component

-- All component actions and queries are separated into the site controller
require 'controllers.site'

app:enable('etlua')
app.layout = require 'views.layout'

local views = {
    -- Static pages
    'about', 'bjc', 'coc', 'contact', 'credits', 'dmca', 'extensions',
    'materials', 'mirrors', 'offline', 'partners', 'privacy', 'requirements',
    'research', 'snapinator', 'snapp', 'source', 'tos',

    -- Simple pages
    'admin', 'blog', 'change_email', 'change_password', 'delete_user',
    'forgot_password', 'forgot_username', 'login', 'sign_up'
}

for _, view in pairs(views) do
    app:get('/' .. view, function (self)
        return { render = view }
    end)
end

-- Pages that use AJAX-enabled components

app:get('/index', function(self)
    -- should be '/', but I need to persuade nginx to understand
    self.Collections = Collections
    self.db = db
    self.user_id = Users:find({ username = 'snapcloud' }).id
    self.new_component = component.new
    return { render = 'index' }
end)

app:get('/explore', function (self)
    self.Projects = Projects
    self.Collections = Collections
    self.db = db
    self.new_component = component.new
    return { render = 'explore' }
end)

app:get('/my_projects', function (self)
    self.Projects = Projects
    self.db = db
    self.username = self.session.username
    self.new_component = component.new
    return { render = 'my_projects' }
end)

app:get('/my_collections', function (self)
    self.Collections = Collections
    self.db = db
    self.user_id = self.current_user.id
    self.new_component = component.new
    return { render = 'my_collections' }
end)

app:get('/user', function (self)
    self.Projects = Projects
    self.Collections = Collections
    self.Users = Users
    self.username = self.queried_user.username
    self.user_id = self.queried_user.id
    self.new_component = component.new
    self.admin_controls =
        self.current_user:has_one_of_roles({'admin', 'moderator'})
    return { render = 'user' }
end)

app:get('/project', function (self)
    self.Remixes = Remixes
    self.project = Projects:find(self.params.username, self.params.projectname)
    self.new_component = component.new
    self.admin_controls =
        self.current_user:has_one_of_roles({'admin', 'moderator'})
    self.reviewer_controls =
        self.current_user:has_one_of_roles({'admin', 'moderator', 'reviewer'})
    return { render = 'project' }
end)

app:get('/examples', function (self)
    self.Collections = Collections
    self.user_id = Users:find({ username = 'snapcloud' }).id
    self.db = db
    self.new_component = component.new
    return { render = 'examples' }
end)

app:get('/collection', function (self)
    local creator = Users:find({ username = self.params.username })
    self.collection =
        Collections:find(creator.id, self.params.collection)
    assert_can_view_collection(self, self.collection)
    self.collection.creator = creator

    if self.collection.thumbnail_id then
        self.collection.thumbnail =
        package.loaded['disk']:retrieve_thumbnail(
            self.collection.thumbnail_id)
    end
    if self.collection.editor_ids then
        self.collection.editors = Users:find_all(
        self.collection.editor_ids,
        { fields = 'username, id' })
    end

    self.new_component = component.new
    return { render = 'collection' }
end)

app:get('/search', function (self)
    self.Projects = Projects
    self.Collections = Collections
    self.Users = Users
    self.db = db
    self.reviewer_controls =
        self.current_user:has_one_of_roles({'admin', 'moderator', 'reviewer'})
    self.new_component = component.new
    return { render = 'search' }
end)

-- Administration and data management pages

app:get('/profile', function (self)
    self.user = self.current_user
    return { render = 'profile' }
end)

app:get('/flags', function (self)
    self.Projects = Projects
    self.new_component = component.new
    assert_has_one_of_roles(self, {'admin', 'moderator', 'reviewer'})
    return { render = 'flags' }
end)


