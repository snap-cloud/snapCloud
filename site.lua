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

local Projects = package.loaded.Projects
local Collections = package.loaded.Collections
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

-- Administration and data management pages

app:get('/profile', function (self)
    self.user = self.current_user
    return { render = 'profile' }
end)
