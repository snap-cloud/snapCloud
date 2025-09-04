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

local util = require("lib.util")
local materials = require('views.static.resources').materials
local material_types = require('views.static.resources').types

require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'

require 'dialogs'

app:enable('etlua')

app.layout = require 'views.layout.application'

local static_pages = {
    'about', 'bjc', 'blog', 'coc', 'contact', 'credits', 'dmca', 'extensions',
    'mirrors', 'offline', 'partners', 'privacy', 'research',
    'snapinator', 'snapp', 'source', 'tos', 'versions',
    -- Disabled because this is out of date.
    -- 'requirements',
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
    self.cache_buster = util.cache_buster()
    -- A front-end method to prefer opening some links (the IDE, mostly) in the same window
    self.prefer_new_tab = false
    if self.current_user and self.session.presist_session ~= 'true' then
        self.prefer_new_tab = true
    end

    -- Store current page in the session so we can redirect to it after login.
    self.session.previous_page = self.session.previous_page or self.req.path

    -- TODO: Set the CSP header to allow only our own domains, or CORS domains.
    -- self.res.headers['Content-Security-Policy'] = "frame-src 'none'"
end)

app:get('index', '/', capture_errors(cached(function (self)
    self.snapcloud_id = Users:find({ username = 'snapcloud' }).id
    return { render = 'index' }
end)))

-- Backwards compatibility.
app:get('/index', function ()
    return { redirect_to = '/' }
end)

app:match('doc', '/doc/:doc_name', respond_to({
    GET = capture_errors(function (self)
        return {
            redirect_to = self:build_url(
                '/static/doc/' .. self.params.doc_name)
        }
    end)
}))

for _, page in pairs(static_pages) do
    app:get('/' .. page, capture_errors(cached(function (self)
        return { render = 'static/' .. page }
    end)))
end

for route, view_path in pairs(user_forms) do
    app:get('/' .. route, capture_errors(cached(function (self)
        self.csrf_token = csrf.generate_token(self)
        self.res.headers['Content-Security-Policy'] = "frame-src 'none'"
        return { render = view_path }
    end)))
end

app:get('/learn', capture_errors(cached(function (self)
    self.materials_by_type = util.group_by_type(materials)
    self.resources_order = {"documentation", "course", "book"}
    self.types = material_types
    return { render = 'static/learn'}
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
    return { render = 'explore' }
end)))

app:get('/collections', capture_errors(cached(function (self)
    self.items = CollectionController.fetch(self)
    return { render = 'collections' }
end)))

app:get('/all_totms', capture_errors(cached(function (self)
    self.items = CollectionController.totms(self)
    return { render = 'all_totms' }
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
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/my_collections', capture_errors(function (self)
    if self.current_user then
        self.items = CollectionController.my_collections(self)
        return { render = 'my_collections' }
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

app:get('/collection/:token/join', capture_errors(function (self)
    assert_user_exists(self)
    self.collection = Collections:find({ join_token = self.params.token })
    assert_exists(self.collection, 'Collection not found')

    if not self.current_user then
        return errorResponse(self,
            'You must be logged in to join a collection.',
            403)
    end

    if not self.collection.editor_ids then
        self.collection.editor_ids = {}
    end
    local editor_ids = self.collection.editor_ids
    local already_editor = false
    for _, id in pairs(editor_ids) do
        if id == self.current_user.id then
            already_editor = true
            break
        end
    end
    if not already_editor then
        table.insert(editor_ids, self.current_user.id)
        Collections:update({ id = self.collection.id }, { editor_ids = db.raw('ARRAY[' .. table.concat(editor_ids, ',') .. ']') })
    end

    return jsonResponse({ redirect = self.collection:url_for('site') })
end))

app:get('/user', capture_errors(function (self)
    assert_user_exists(self)
    self.username = self.queried_user.username
    self.user_id = self.queried_user.id
    return { render = 'user' }
end))

app:get('/user_collections/:username', capture_errors(cached(function (self)
    assert_user_exists(self)
    self.params.user_id = self.queried_user.id
    self.items = CollectionController.user_collections(self)
    return { render = 'collections' }
end)))

app:get('/user_projects/:username', capture_errors(cached(function (self)
    assert_user_exists(self)
    self.items = ProjectController.user_projects(self)
    return { render = 'explore' }
end)))

-- Display an embedded collection view.
-- Designed to be a single row view, but can be expanded.
app:get('/carousel', capture_errors(cached(function (self)
    assert_user_exists(self)
    local creator = self.queried_user
    -- This parameter needs to be set for the carousel view.
    -- It doesn't not ineracte correctly with the items_per_page passed to the
    -- projects() method below.
    -- In this current flow, we only have JS
    self.items_per_page = self.params.items_per_page or 4
    self.items_per_row = self.params.items_per_row or 4

    self.collection = assert_exists(Collections:find(creator.id, self.params.collection))
    assert_can_view_collection(self, self.collection)
    self.collection.creator = creator
    -- Pass a different items_per_page to the controller to query more projects.
    self.ignore_page_count = true
    self.items = CollectionController.projects({
        params = self.params,
        items_per_page = 50,
        collection = self.collection
    })
    self.title = self.collection.name
    self.href = self.collection:url_for('site')
    self.show_if_empty = true
    return { render = 'carousel', layout = 'embedded' }
end)))

app:get('/followed', capture_errors(cached(function (self)
    if self.current_user then
        self.items = ProjectController.followed_projects(self)
        return { render = 'followed' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/followed_users', capture_errors(cached(function (self)
    if self.current_user then
        self.items = UserController.followed_users(self)
        return { render = 'followed_users' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/my_followers', capture_errors(cached(function (self)
    if self.current_user then
        self.items = UserController.follower_users(self)
    return { render = 'my_followers' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/bookmarked', capture_errors(cached(function (self)
    if self.current_user then
        self.items = ProjectController.bookmarked_projects(self)
        return { render = 'bookmarked' }
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

    return { render = 'project' }
end))

-- TODO: Should be able to consolidate these pages.
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
        return { render = 'admin/index' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/admin/bookmarks_feed', capture_errors(cached(function (self)
    if self.current_user then
        assert_min_role(self, 'reviewer')
        self.items = ProjectController.all_recent_bookmarks(self)
        self.page_title = 'recent_bookmarks'
        return { render = 'admin/basic_project_list' }
    else
        return { redirect_to = self:build_url('/') }
    end
end)))

app:get('/flags', capture_errors(function (self)
    if self.current_user then
        assert_min_role(self, 'reviewer')
        self.params.items_per_page = self.params.items_per_page or 18
        self.items = ProjectController.flagged_projects(self)
        self.page_title = 'flagged_projects'
        return { render = 'admin/basic_project_list' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))

app:get('/user_admin', capture_errors(function (self)
    self.items_per_page = 150
    if self.current_user then
        assert_min_role(self, 'moderator')
        self.items = UserController.fetch(self)
        return { render = 'admin/user_admin' }
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
            return { render = true }
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
                return { render = true }
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
    return { render = 'teacher/index' }
end))

app:get('/bulk', capture_errors(function (self)
    assert_exists(self.current_user)
    if (not self.current_user.is_teacher) then
        assert_admin(self)
    end
    return { render = 'teacher/bulk' }
end))

app:get('/learners', capture_errors(function (self)
    assert_exists(self.current_user)
    if (not self.current_user.is_teacher) then
        assert_admin(self)
    end

    self.items_per_page = 150
    if self.current_user and self.current_user.is_teacher then
        self.items = UserController.learners(self)
        return { render = 'teacher/learners' }
    else
        return { redirect_to = self:build_url('index') }
    end
end))

-- Tools
-- app:get('/localize', capture_errors(function (self)
--     return { render = 'localize' }
-- end))
