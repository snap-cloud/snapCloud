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
        end,
        user_collections = function (self)
        end,
        collection = function (self)
        end,
        collection_memberships = function (self)
        end
    },
    POST = {
        collection = function (self)
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
        end
    },
    DELETE = {
        collection = function (self)
        end,
        collection_memberships = function (self)
        end
    }
}
