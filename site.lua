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

require 'dialogs'

app:enable('etlua')
app.layout = require 'views.layout'

local views = {
    -- Static pages
    'about', 'bjc', 'coc', 'contact', 'credits', 'dmca', 'extensions',
    'materials', 'mirrors', 'offline', 'partners', 'privacy', 'requirements',
    'research', 'snapinator', 'snapp', 'source', 'tos',

    -- Simple pages
    'blog', 'change_email', 'change_password', 'delete_user', 'forgot_password',
    'forgot_username', 'sign_up', 'login',
}

for _, view in pairs(views) do
    app:get('/' .. view, capture_errors(cached(function (self)
        return { render = view }
    end)))
end

app:get('/embed', capture_errors(function (self)
    -- Backwards compatibility with previous URL params
    self.project = Projects:find(
        tostring(self.params.user or self.params.username),
        self.params.project or self.params.projectname
    )
    return { render = 'embed', layout = false }
end))

app:get('/explore', capture_errors(cached(function (self)
    self.items = ProjectController.fetch(self)
    return { render = 'explore' }
end)))

app:get('/collections', capture_errors(cached(function (self)
    self.items = CollectionController.fetch(self)
    return { render = 'collections' }
end)))

app:get('/users', capture_errors(cached(function (self)
    self.items_per_page = 51
    self.items = UserController.fetch(self)
    if not self.params.search_term then self.params.search_term = '' end
    return { render = 'users' }
end)))

app:get('/my_projects', capture_errors(function (self)
    if self.current_user then
        self.items = ProjectController.my_projects(self)
        return { render = 'my_projects' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:get('/my_collections', capture_errors(function (self)
    if self.current_user then
        self.items = CollectionController.my_collections(self)
        return { render = 'my_collections' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:get('/collection', capture_errors(function (self)
    local creator = Users:find({ username = tostring(self.params.username) })
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

    self.items_per_page = 12
    self.items = CollectionController.projects(self)

    return { render = 'collection' }
end))

local index = capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'index' }
end))

app:get('/', index)
app:get('/index', index)

app:get('/user', capture_errors(function (self)
    self.username = self.queried_user.username
    self.user_id = self.queried_user.id
    return { render = 'user' }
end))

app:get('/user_collections/:username', capture_errors(cached(function (self)
    self.params.user_id = self.queried_user.id
    self.items = CollectionController.user_collections(self)
    return { render = 'collections' }
end)))

app:get('/user_projects/:username', capture_errors(cached(function (self)
    self.items = ProjectController.user_projects(self)
    return { render = 'explore' }
end)))

-- Display an embedded collection view.
app:get('/carousel', capture_errors(cached(function (self)
    local creator = Users:find({ username = tostring(self.params.username) })
    self.params.page_number = self.params.page_number or 1
    self.collection = Collections:find(creator.id, self.params.collection)
    assert_can_view_collection(self, self.collection)
    self.collection.creator = creator
    self.items = CollectionController.projects(self)
    self.title = self.collection.name
    self.show_if_empty = true
    return { render = 'carousel', layout = 'embedded' }
end)))

app:get('/followed', capture_errors(cached(function (self)
    if self.current_user then
        self.items = ProjectController.followed_projects(self)
        return { render = 'followed' }
    else
        return { redirect_to = self:build_url('index') }
    end
end)))

app:get('/project', capture_errors(function (self)
    -- Backwards compatibility with previous URL params
    self.project = Projects:find(
        tostring(self.params.user or self.params.username),
        self.params.project or self.params.projectname
    )

    -- check whether this is a remix of another project
    local remix =
        Remixes:select('WHERE remixed_project_id = ?', self.project.id)
    if remix[1] then
        self.remixed_from =
            Projects:select('WHERE id = ?', remix[1].original_project_id)[1]
    end

    -- check whether the current user has already flagged this project
    if self.current_user then
        self.project.flagged =
            FlaggedProjects:select(
                'WHERE project_id = ? AND flagger_id = ?',
                self.project.id,
                self.current_user.id
            )[1] ~= nil
    end

    return { render = 'project' }
end))

app:get('/examples', capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'examples' }
end)))

app:get('/events', capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'events' }
end)))

app:get('/search', capture_errors(function (self)
    self.reviewer_controls =
        self.current_user and self.current_user:has_min_role('reviewer')
    return { render = 'search' }
end))

-- Administration and data management pages

app:get('/profile', capture_errors(function (self)
    if self.current_user then
        self.user = self.current_user
        return { render = 'profile' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:get('/admin', capture_errors(function (self)
    if self.current_user then
        assert_min_role(self, 'reviewer')
        return { render = 'admin' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:get('/flags', capture_errors(function (self)
    if self.current_user then
        assert_min_role(self, 'reviewer')
        items = ProjectController.flagged_projects(self)
        return { render = 'flags' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:get('/user_admin', capture_errors(function (self)
    self.items_per_page = 150
    if self.current_user then
        assert_min_role(self, 'moderator')
        self.items = UserController.fetch(self)
        return { render = 'user_admin' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:get('/zombie_admin', capture_errors(function (self)
    self.items_per_page = 150
    if self.current_user then
        assert_min_role(self, 'moderator')
        self.items = UserController.zombies(self)
        return { render = 'zombie_admin' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

app:match('/totm', respond_to({
    GET = capture_errors(function (self)
        if self.current_user then
            assert_min_role(self, 'moderator')
            return { render = 'totm' }
        else
            return { redirect_to = self:build_url('index') }
        end
    end),
    POST = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        local file = self.params.uploaded_file
        if file then
            local disk = package.loaded.disk
            if disk:save_totm_banner(file) then
                return { render = 'totm' }
            end
        end
        return errorResponse()
    end)
}))

app:get('/carousel_admin', capture_errors(function (self)
    assert_min_role(self, 'moderator')
    return { render = 'carousel_admin' }
end))

app:get('/ip_admin', capture_errors(function (self)
    assert_min_role(self, 'admin')
    self.ips = SiteController.banned_ips(self)
    return { render = 'ip_admin' }
end))

-- Tools

--[[
app:get('/localize', capture_errors(function (self)
    return { render = 'localize' }
end))
]]--
