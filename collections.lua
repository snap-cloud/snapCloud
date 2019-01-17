-- Collections API module
-- ======================
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
local assert_error = app_helpers.assert_error

local CollectionsController = require('controllers.CollectionsController')

app:match(api_route('collections_list', '/collections', {
    -- Methods:     GET
    -- Description: If requesting user is an admin, get a paginated list of all
    --              collections with name matching matchtext, if provided.
    --              Returns public collections
    -- Parameters:  matchtext, page, pagesize

    GET = CollectionsController.Index
}))

app:match(api_route('user_collections', '/users/:username/collections', {
    -- Methods:     GET, POST
    -- Description: Get a paginated list of all a particular user's collections
    --              with name matching matchtext, if provided.
    --              Returns only public collections, if another user.
    -- Parameters:  GET: username, matchtext, page, pagesize
    --              POST: username, collection_name, description, published,
    --                    shared, thumbnail_id

    GET = CollectionsController.UserIndex,
    POST = CollectionsController.Create
}))

app:match(api_route('collections',
          '/users/:username/collections/:collection_slug', {
    -- Methods:     GET, POST, DELETE
    -- Description: Get the info about a collection.
    --              Create and a delete a collection.
    -- Parameters:  username, collection_name, ...

    GET = CollectionsController.Show,
    POST = CollectionsController.Update,
    DELETE = CollectionsController.Delete
}))

app:match(api_route('collection_memberships',
          '/users/:username/collections/:collection_slug/items(/:item_id)', {
    -- Methods:     GET, POST, DELETE
    -- Description: Get a paginated list of all items in a collection.
    --              Add or remove items from the collection.
    -- Parameters:  username, collection_slug

    GET = CollectionsController.ShowMembers,
    POST = CollectionsController.AddMember,
    DELETE = CollectionsController.DeleteMember
}))
