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
    GET = {
        -- TODO
        collections_list = function (self)
            -- GET /collections
            -- Description: If requesting user is an admin, get a paginated list of all
            --              collections with name matching matchtext, if provided.
            --              Returns public collections
            -- Parameters:  matchtext, page, pagesize
        end,
        user_collections = function (self)
            -- GET /users/:username/collections
            -- Description: Get a paginated list of all a particular user's collections
            --              with name matching matchtext, if provided.
            --              Returns only public collections, if another user.
            -- Parameters:  GET: username, matchtext, page, pagesize
        end,
        collection = function (self)
            -- GET /users/:username/collections/:collection_slug
            -- Description: Get info about a collection.
            -- Parameters:  username, collection_name, ...
        end,
        collection_memberships = function (self)
            -- GET /users/:username/collections/:collection_slug/items(/:item_id)
            -- Description: Get a paginated list of all items in a collection.
            -- Parameters:  username, collection_slug
        end
    },
    POST = {
        collection = function (self)
            -- POST /users/:username/collections/:collection_slug
            -- Description: Create a collection.
            -- Parameters:  username, collection_name, ...

            -- TODO (temp off): assert_all({ assert_logged_in, assert_users_match }, self)
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
        end,
        collection_memberships = function (self)
            -- POST /users/:username/collections/:collection_slug/items(/:item_id)
            -- Description: Add an item to a collection.
            -- Parameters:  username, collection_slug, item_id
        end
    },
    DELETE = {
        collection = function (self)
            -- DELETE /users/:username/collections/:collection_slug
            -- Description: Delete a particular collection.
        end,
        collection_memberships = function (self)
            -- DELETE /users/:username/collections/:collection_slug/items(/:item_id)
            -- Description: Remove an item from a collection.
            -- Parameters:  username, collection_slug
        end
    }
}
