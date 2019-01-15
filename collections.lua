-- Collections API module
-- ======================
--
-- See static/API for API description
--
-- Written by Bernat Romagosa, Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa, Michael
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
local db = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local validate = package.loaded.validate
local Model = package.loaded.Model
local util = package.loaded.util
local respond_to = package.loaded.respond_to
local json_params = package.loaded.json_params
local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Collections = package.loaded.Collections

local app_helpers = require("lapis.application")

-- a simple helper for conditionally setting the timestamp fields
-- TODO: move to a more useful location.
local current_time_or_nil = function(option)
    if option == 'true' then
        return db.raw('now()')
    end
    return nil
end

app:match('collections_list', '/collections', respond_to({
    -- Methods:     GET
    -- Description: If requesting user is an admin, get a paginated list of all
    --              collections with name matching matchtext, if provided.
    --              Returns public collections
    -- Parameters:  matchtext, page, pagesize

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO
    end)
}))

app:match('user_collections', '/users/:username/collections', respond_to({
    -- Methods:     GET, POST
    -- Description: Get a paginated list of all a particular user's collections
    --              with name matching matchtext, if provided.
    --              Returns only public collections, if another user.
    -- Parameters:  GET: username, matchtext, page, pagesize
    --              POST: username, collection_name, description, published,
    --                    shared, thumbnail_id

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO
    end),
    POST = capture_errors(function (self)
        print('RESPONDING TO REQUEST')
        -- assert_all({ assert_logged_in, assert_users_match }, self)
        local request_user = assert_user_exists(self)

        -- Read request body and parse it into JSON
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        local body = body_data and util.from_json(body_data) or nil
        -- TODO: Model validations or this?
        -- validate.assert_valid(body, { { 'name', exists = true }, })

        collection = app_helpers.assert_error(Collections:create({
            name = body.name,
            slug = util.slugify(body.name),
            creator_id = request_user.id,
            description = body.description,
            published = body.published,
            published_at = current_time_or_nil(body.published),
            shared = body.shared,
            shared_at = current_time_or_nil(body.shared),
            thumbnail_id = body.thumbnail_id
        }))

        return jsonResponse(collection)
    end)
}))

app:match('collections',
          '/users/:username/collections/:collection_slug', respond_to({
    -- Methods:     GET, POST, DELETE
    -- Description: Get the info about a collection.
    --              Create and a delete a collection.
    -- Parameters:  username, collection_name, ...

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO return info about this collection
    end),
    POST = capture_errors(function (self)
        -- TODO: update collection info
    end),
    DELETE = capture_errors(function (self)
        -- delete the collection, remove all project links
    end)
}))

app:match('collection_memberships',
          '/users/:username/collections/:collection_slug/items(/:item_id)', respond_to({
    -- Methods:     GET, DELETE
    -- Description: Get a paginated list of all items in a collection.
    --              Add or remove items from the collection.
    -- Parameters:  username, collection_slug

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO list the items in this collection
        -- Perhaps this eventually supports filtering
    end),
    POST = capture_errors(function (self)
        -- TODO add a project to the collection
    end),
    DELETE = capture_errors(function (self)
        -- TODO remove item from collection memberships
    end)
}))
