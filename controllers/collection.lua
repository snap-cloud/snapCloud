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

local db = package.loaded.db
local cached = package.loaded.cached
local util = package.loaded.util
local validate = package.loaded.validate
local json_params = package.loaded.app_helpers.json_params
local yield_error = package.loaded.app_helpers.yield_error
local assert_error = package.loaded.app_helpers.assert_error

local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Collections = package.loaded.Collections
local CollectionMemberships = package.loaded.CollectionMemberships

require 'responses'
require 'validation'

-- a simple helper for conditionally setting the timestamp fields
-- TODO: move to a more useful location.
local current_time_or_nil = function (option)
    if option == true then
        return db.raw('now()')
    end
    return nil
end

CollectionController = {
    GET = {
        collections = cached({
            -- GET /collections
            -- Description: Get a paginated list of all published collections with name
            --              matching matchtext, if provided.
            -- Parameters:  matchtext, page, pagesize
            exptime = 30, -- cache expires after 30 seconds
            function (self)
                local query = 'where published'

                -- Apply where clauses
                if self.params.matchtext then
                    query = query ..
                        db.interpolate_query(
                            ' and (name ILIKE ? or description ILIKE ?)',
                            self.params.matchtext,
                            self.params.matchtext
                        )
                end

                local paginator =
                    Collections:paginated(
                        query .. ' order by published_at desc',
                        { per_page = self.params.pagesize or 16 }
                    )

                local collections = self.params.page and paginator:get_page(self.params.page) or paginator:get_all()

                return jsonResponse({
                    pages = self.params.page and paginator:num_pages() or nil,
                    collections = collections
                })
            end
        }),

        user_collections = function (self)
            -- GET /users/:username/collections
            -- Description: Get a paginated list of all a particular user's collections
            --              with name or description matching matchtext, if provided.
            --              Returns only public collections, if another user.
            -- Parameters:  username, matchtext, page, pagesize

            assert_user_exists(self)

            local order = 'updated_at'

            if not (users_match(self)) then
                if not self.current_user or not self.current_user:isadmin() then
                    self.params.published = 'true'
                    order = 'published_at'
                end
            end

            assert_user_exists(self)

            local query = db.interpolate_query('where creator_id = ?', self.queried_user.id)

            -- Apply where clauses
            if self.params.published ~= nil then
                query = query ..
                    db.interpolate_query(
                        ' and published = ?',
                        self.params.published == 'true'
                    )
            end

            if self.params.matchtext then
                query = query ..
                    db.interpolate_query(
                        ' and (name ILIKE ? or description ILIKE ?)',
                        self.params.matchtext,
                        self.params.matchtext
                    )
            end

            local paginator = Collections:paginated(
                query .. ' order by ' .. order .. ' desc',
                {
                    per_page = self.params.pagesize or 16,
                    prepare_results = function (collections)
                        Users:include_in(collections, 'creator_id', { fields = 'username' });
                        return collections
                    end
                })

            local collections = self.params.page and paginator:get_page(self.params.page) or paginator:get_all()

            return jsonResponse({
                pages = self.params.page and paginator:num_pages() or nil,
                collections = collections
            })
        end,

        collection = function (self)
            -- GET /users/:username/collections/:name
            -- Description: Get info about a collection.
            -- Parameters:  username, name, ...

            local collection = assert_collection_exists(self)
            assert_can_view_collection(self, collection)
            collection.projects_count = collection:count_projects()
            return jsonResponse(collection)
        end,

        collection_projects = function (self)
            -- GET /users/:username/collections/:name/projects
            -- Description: Get a paginated list of all projects in a collection.
            -- Parameters:  username, name
            -- TODO: Not sure how to pass a pagesize to this. :/
            -- Note: May need to re-write this as a method w/o using the `relations`
            local collection = assert_collection_exists(self)
            assert_can_view_collection(self, collection)
            local projects = collection:get_projects()
            return jsonResponse(projects:get_page(self.params.page or 1))
        end,

        collection_project = function (self)
            -- GET /users/:username/collections/:name/projects/:project_id
            -- Description: Get a project belonging to a collection
            -- Parameters:  username, name
            local collection = assert_collection_exists(self)
            return jsonResponse(CollectionMemberships:find(collection.id, self.params.project_id))
        end
    },

    POST = {
        collection = json_params(function (self)
            -- POST /users/:username/collections/:name
            -- Description: Create a collection.
            -- Parameters:  username, ...

            assert_users_match(self)
            local params = self.params
            local collection = Collections:find(self.queried_user.id, params.name)

            if collection then
                -- TODO: I think we can extract these into functions.
                local published = params.published ~= nil and params.published == true
                local published_at = (published and collection.published_at) or
                current_time_or_nil(published)
                local shared = params.shared ~= nil and params.shared == true
                local shared_at = (shared and collection.shared_at) or
                current_time_or_nil(shared)

                collection:update({
                    name = params.name or collection.name,
                    description = params.description or collection.description,
                    published = published,
                    published_at = published_at,
                    shared = shared,
                    shared_at = shared_at,
                    thumbnail_id = params.thumbnail_id or collection.thumbnail_id
                })

                return jsonResponse(collection)
            end

            return jsonResponse(assert_error(Collections:create({
                name = params.name,
                creator_id = self.queried_user.id,
                description = params.description,
                published = params.published == true,
                published_at = current_time_or_nil(params.published),
                shared = params.shared == true,
                shared_at = current_time_or_nil(params.shared),
                thumbnail_id = params.thumbnail_id
            })))
        end),

        add_project = function (self)
            -- POST /users/:username/collections/:name/projects
            -- Description: Add a project to a collection.
            -- Body: projectname, username (project author)
            assert_users_match(self)

            ngx.req.read_body()
            local body_data = ngx.req.get_body_data()
            local body = body_data and util.from_json(body_data) or nil

            local collection = assert_collection_exists(self)
            local project = Projects:find(body.username, body.projectname)

            assert_user_can_add_project_to_collection(project)

            -- TODO: postgres will error if you do this twice. Do we need to catch that?
            return jsonResponse(assert_error(CollectionMemberships:create({
                collection_id = collection.id,
                project_id = project.id,
                user_id = self.queried_user.id
            })))
        end

    },

    DELETE = {
        collection = function (self)
            -- DELETE /users/:username/collections/:name
            -- Description: Delete a particular collection.
            local collection = assert_collection_exists(self)
            if not users_match(self) then
                assert_has_one_of_roles(self, { 'moderator', 'admin' })
            end
            collection:delete()
            return okResponse('Collection deleted')
        end,

        collection_project = function (self)
            -- DELETE /users/:username/collections/:name/projects/:project_id
            -- Description: Remove a project from a collection.
            -- Parameters:  username, name
        end
    }
}
