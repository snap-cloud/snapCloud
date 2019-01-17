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

app:match('collections_list', '/collections', respond_to({
    -- Methods:     GET
    -- Description: If requesting user is an admin, get a paginated list of all
    --              collections with name matching matchtext, if provided.
    --              Returns public collections
    -- Parameters:  matchtext, page, pagesize

    GET = CollectionsController.Index
}))

app:match('user_collections', '/users/:username/collections', respond_to({
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
