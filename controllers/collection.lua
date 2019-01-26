-- Collections API controller
-- ==========================
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

local util = package.loaded.util
local validate = package.loaded.validate

local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Collections = package.loaded.Collections

require 'responses'
require 'validation'

-- a simple helper for conditionally setting the timestamp fields
-- TODO: move to a more useful location.
local current_time_or_nil = function(option)
    if option == 'true' then
        return db.raw('now()')
    end
    return nil
end

CollectionController = {
    GET = {}, POST = {}, DELETE = {}
}

CollectionController.GET.collections_list = function (self)
    -- GET /collections
    -- Description: If requesting user is an admin, get a paginated list of all
    --              collections with name matching matchtext, if provided.
    --              Returns public collections
    -- Parameters:  matchtext, page, pagesize
    assert_admin(self)
    local page_size = self.params.pagesize or 16
    local paginator = Collections:paginated({ per_page = page_size })
    return jsonResponse(paginator:get_page(self.params.page or 1))
end

CollectionController.GET.user_collections = function (self)
    -- TODO: add filtering
    -- GET /users/:username/collections
    -- Description: Get a paginated list of all a particular user's collections
    --              with name matching matchtext, if provided.
    --              Returns only public collections, if another user.
    -- Parameters:  GET: username, matchtext, page, pagesize

    assert_user_exists(self)
    if users_match(self) then
        return jsonResponse(self.queried_user:get_collections())
    else
        return jsonResponse(self.queried_user:get_public_collections())
    end
end

CollectionController.GET.collections = function (self)
    -- GET /users/:username/collections/:collection_slug
    -- Description: Get info about a collection.
    -- Parameters:  username, collection_slug, ...

    local collection = assert_collection_exists(self)
    local project_count = collection:count_projects()
    collection.projects_count = project_count
    return jsonResponse(collection)
end

CollectionController.POST.collections = function (self)
    -- POST /users/:username/collections/:collection_slug
    -- Description: Create a collection.
    -- Parameters:  username, collection_name, ...

    -- assert_users_match(self)
    -- Must assert name before generating a slug.
    validate.assert_valid(self.params, { { 'name', exists = true } })

    return jsonResponse(assert_error(Collections:create({
        name = self.params.name,
        slug = util.slugify(self.params.name),
        creator_id = self.request_user.id,
        description = self.params.description,
        published = self.params.published,
        published_at = current_time_or_nil(self.params.published),
        shared = self.params.shared,
        shared_at = current_time_or_nil(self.params.shared),
        thumbnail_id = self.params.thumbnail_id
    })))
end

CollectionController.DELETE.collections = function (self)
    -- DELETE /users/:username/collections/:collection_slug
    -- Description: Delete a particular collection.
end

CollectionController.GET.collection_memberships = function (self)
    -- GET /users/:username/collections/:collection_slug/projects(/:project_id)
    -- Description: Get a paginated list of all projects in a collection.
    -- Parameters:  username, collection_slug
    local collection = assert_collection_exists(self)
    if self.params.project_id then
        return jsonResponse(CollectionMemberships:find(collection.id,
                                                       self.params.project_id))
    end
    local projects = CollectionMemberships:paginated(
        "WHERE collection_id = ?", collection.id, {
            per_page = self.params.page or 16,
            prepare_results = function(posts)
                Projects:include_in(posts, "project_id")
                return posts
            end
        })
    -- local memberships = collection:get_memberships()
    -- a list of projects agumented with date_added
    return projects:get_page(self.params.page or 1)
end

CollectionController.POST.collection_memberships = function (self)
    -- POST /users/:username/collections/:collection_slug/projects(/:project_id)
    -- Description: Add a project to a collection.
    -- Parameters:  username, collection_slug, project_id

    -- TODO (temp off): assert_all({ assert_logged_in, assert_users_match }, self)
    local collection = assert_collection_exists(self)
    local project = Project:find({ id = self.params.project_id })

    assert_user_can_view_project(project)

    return jsonResponse(CollectionMemberships:create({
        collection_id = collection.id,
        project_id = project.id
    }))
end

CollectionController.DELETE.collection_memberships = function (self)
    -- DELETE /users/:username/collections/:collection_slug/projects(/:project_id)
    -- Description: Remove a project from a collection.
    -- Parameters:  username, collection_slug
end
