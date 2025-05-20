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
local cached = package.loaded.cached
local respond_to = package.loaded.respond_to

local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Remixes = package.loaded.Remixes
local Collections = package.loaded.Collections
local FlaggedProjects = package.loaded.FlaggedProjects
local csrf = require("lapis.csrf")
local assert_exists = require('validation').assert_exists

local materials = require('views.static.resources').materials
local material_types = require('views.static.resources').types
local group_by_type = require("lib.util").group_by_type

require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'

require 'dialogs'

app:enable('etlua')
app.layout = require 'views.layout'

local static_pages = {
    'about', 'bjc', 'blog', 'coc', 'contact', 'credits', 'dmca', 'extensions',
    'mirrors', 'offline', 'partners', 'privacy', 'research',
    'snapinator', 'snapp', 'source', 'tos'
}

local user_forms = {}
-- Simple static pages that contain user interactions.
-- These pages should all have a CSRF token and not allow iframes.
-- The map is route/name to view location.
user_forms['login'] = 'sessions/login'
user_forms['forgot_password'] = 'sessions/forgot_password'
user_forms['forgot_username'] = 'sessions/forgot_username'
user_forms['change_password'] = 'sessions/change_password'
user_forms['change_email'] = 'users/change_email'
user_forms['sign_up'] = 'users/sign_up'
user_forms['delete_user'] = 'users/delete_user'

app:before_filter(function (self)
    -- A front-end method to prefer opening some links (the IDE, mostly) in the same window
    self.prefer_new_tab = false
    if self.current_user and self.session.presist_session ~= 'true' then
        self.prefer_new_tab = true
    end
end)

app:get('index', '/', capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'index_bs', layout = 'layout_bs' }
end)))

-- Backwards compatibility.
app:get('/index', function ()
    return { redirect_to = '/' }
end)

app:match('doc', '/doc/:doc_name', respond_to({
    GET = capture_errors(function (self)
        return {
            redirect_to = self:build_url(
                '/static/doc/' ..  self.params.doc_name)
        }
    end)
}))

for _, page in pairs(static_pages) do
    app:get('/' .. page, capture_errors(cached(function (self)
        return { render = 'static/' .. page, layout = 'layout_bs' }
    end)))
end

for route, view_path in pairs(user_forms) do
    app:get('/' .. route, capture_errors(cached(function (self)
        self.csrf_token = csrf.generate_token(self)
        self.res.headers['Content-Security-Policy'] = "frame-src 'none'"
        return { render = view_path, layout = 'layout_bs' }
    end)))
end

app:get('/learn', capture_errors(cached(function (self)
    self.materials_by_type = group_by_type(materials)
    self.typesOrder = {"documentation", "course", "book"}
    self.types = material_types
    return { render = 'static/learn', layout = 'layout_bs'}
end)))

app:get('/materials', function ()
    return { redirect_to = '/learn' }
end)

app:get('/embed', capture_errors(function (self)
    -- Backwards compatibility with previous URL params
    self.project = Projects:find(
        tostring(self.params.user or self.params.username),
        self.params.project or self.params.projectname
    )
    assert_project_exists(self)
    return { render = 'embed', layout = false }
end))

app:get('/explore', capture_errors(cached(function (self)
    self.items = ProjectController.fetch(self)
    return { render = 'explore', layout = 'layout_bs' }
end)))

app:get('/collections', capture_errors(cached(function (self)
    self.items = CollectionController.fetch(self)
    return { render = 'collections', layout = 'layout_bs' }
end)))

app:get('/all_totms', capture_errors(cached(function (self)
    self.items = CollectionController.totms(self)
    return { render = 'all_totms', layout = 'layout_bs' }
end)))

app:get('/users', capture_errors(cached(function (self)
    self.items_per_page = 51
    self.items = UserController.fetch(self)
    if not self.params.search_term then self.params.search_term = '' end
    return { render = 'users', layout = 'layout_bs' }
end)))

app:get('/my_projects', capture_errors(function (self)
    if self.current_user then
        self.items = ProjectController.my_projects(self)
        return { render = 'my_projects', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/my_collections', capture_errors(function (self)
    if self.current_user then
        self.items = CollectionController.my_collections(self)
        return { render = 'my_collections', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/collection', capture_errors(function (self)
    assert_user_exists(self)
    local creator = self.queried_user

    self.collection =
        assert_exists(Collections:find(creator.id, self.params.collection))
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

app:get('/user', capture_errors(function (self)
    assert_user_exists(self)
    self.username = self.queried_user.username
    self.user_id = self.queried_user.id
    return { render = 'user', layout = 'layout_bs' }
end))

app:get('/user_collections/:username', capture_errors(cached(function (self)
    assert_user_exists(self)
    self.params.user_id = self.queried_user.id
    self.items = CollectionController.user_collections(self)
    return { render = 'collections', layout = 'layout_bs' }
end)))

app:get('/user_projects/:username', capture_errors(cached(function (self)
    assert_user_exists(self)
    self.items = ProjectController.user_projects(self)
    return { render = 'explore', layout = 'layout_bs' }
end)))

-- Display an embedded collection view.
app:get('/carousel', capture_errors(cached(function (self)
    assert_user_exists(self)
    local creator = self.queried_user
    self.params.items_per_row = self.params.items_per_page or 5
    self.params.page_number = self.params.page_number or 1
    self.collection = assert_exists(Collections:find(creator.id, self.params.collection))
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
        return { render = 'followed', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/followed_users', capture_errors(cached(function (self)
    if self.current_user then
        self.items = UserController.followed_users(self)
        return { render = 'followed_users', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/my_followers', capture_errors(cached(function (self)
    if self.current_user then
        self.items = UserController.follower_users(self)
    return { render = 'my_followers', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/bookmarked', capture_errors(cached(function (self)
    if self.current_user then
        self.items = ProjectController.bookmarked_projects(self)
        return { render = 'bookmarked', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:match('project', '/project', capture_errors(function (self)
    -- Backwards compatibility with previous URL params
    if self.params.user and self.params.project then
        -- Just redirect using the new URL params format
        return {
            redirect_to =
                self:url_for(
                    'project',
                    nil,
                    {
                        username = self.params.user,
                        projectname = self.params.project
                    }
                )
        }
    end

    self.project = Projects:find(
        tostring(self.params.username),
        self.params.projectname
    )
    assert_project_exists(self)
    assert_can_view_project(self)

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

    return { render = 'project_bs', layout = 'layout_bs' }
end))

-- TODO: Should be able to consolidate these pages.
app:get('/examples', capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'examples', layout = 'layout_bs' }
end)))

app:get('/events', capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'events', layout = 'layout_bs' }
end)))

app:get('/search', capture_errors(function (self)
    self.reviewer_controls =
        self.current_user and self.current_user:has_min_role('reviewer')
    return { render = 'search', layout = 'layout_bs' }
end))


app:get('/profile', capture_errors(function (self)
    if self.current_user then
        self.user = self.current_user
        return { render = 'profile' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

-- Administration and data management pages

app:get('/admin', capture_errors(function (self)
    if self.current_user then
        assert_min_role(self, 'reviewer')
        return { render = 'admin/index', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/flags', capture_errors(function (self)
    if self.current_user then
        assert_min_role(self, 'reviewer')
        items = ProjectController.flagged_projects(self)
        return { render = 'admin/flags' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/user_admin', capture_errors(function (self)
    self.items_per_page = 150
    if self.current_user then
        assert_min_role(self, 'moderator')
        self.items = UserController.fetch(self)
        return { render = 'admin/user_admin', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/zombie_admin', capture_errors(function (self)
    self.items_per_page = 150
    if self.current_user then
        assert_min_role(self, 'moderator')
        self.items = UserController.zombies(self)
        return { render = 'admin/zombie_admin' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:match('admin/totm', '/totm', respond_to({
    GET = capture_errors(function (self)
        if self.current_user then
            assert_min_role(self, 'moderator')
            return { render = true, layout = 'layout_bs' }
        else
            return { redirect_to = self:build_url('/') }
        end
    end),
    POST = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        local file = self.params.uploaded_file
        if file then
            local disk = package.loaded.disk
            if disk:save_totm_banner(file) then
                return { render = true, layout = 'layout_bs' }
            end
        end
        return errorResponse(self)
    end)
}))

app:get('/carousel_admin', capture_errors(function (self)
    assert_min_role(self, 'moderator')
    return { render = 'admin/carousel_admin' }
end))

app:get('/ip_admin', capture_errors(function (self)
    assert_min_role(self, 'admin')
    self.ips = SiteController.banned_ips(self)
    return { render = 'admin/ip_admin' }
end))

-- Teachers

app:get('/teacher', capture_errors(function (self)
    assert_exists(self.current_user)
    if (not self.current_user.is_teacher) then
        assert_admin(self)
    end
    return { render = 'teacher/index', layout = 'layout_bs' }
end))

app:get('/bulk', capture_errors(function (self)
    assert_exists(self.current_user)
    if (not self.current_user.is_teacher) then
        assert_admin(self)
    end
    return { render = 'teacher/bulk', layout = 'layout_bs' }
end))

app:get('/learners', capture_errors(function (self)
    assert_exists(self.current_user)
    if (not self.current_user.is_teacher) then
        assert_admin(self)
    end

    self.items_per_page = 150
    if self.current_user and self.current_user.is_teacher then
        self.items = UserController.learners(self)
        return { render = 'teacher/learners', layout = 'layout_bs' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

-- Tools
--[[
app:get('/localize', capture_errors(function (self)
    return { render = 'localize' }
end))
]]--
