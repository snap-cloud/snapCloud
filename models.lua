-- Database abstractions
-- =====================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

package.loaded.Model = require('lapis.db.model').Model

-- Finding a row by a value that can't be of the column's type is "not
-- found", not a Postgres type error. Column types come from Lapis'
-- cached information_schema lookup (one query per model per worker).
local Model = package.loaded.Model
local lapis_find = Model.find

local fits_type = {
    integer = function (value)
        return tostring(value):match('^%-?%d+$') ~= nil
    end,
    boolean = function (value)
        return type(value) == 'boolean' or
            tostring(value):match('^[tf]$') ~= nil or
            tostring(value):match('^true$') ~= nil or
            tostring(value):match('^false$') ~= nil
    end
}
fits_type.bigint = fits_type.integer
fits_type.smallint = fits_type.integer
-- A query arg with no value (?collection) arrives as boolean true.
fits_type.text = function (value) return type(value) ~= 'boolean' end
fits_type['character varying'] = fits_type.text

Model.find = function (self, ...)
    local conditions = ...
    if type(conditions) ~= 'table' and select('#', ...) > 0 then
        -- positional form: values for the primary keys, in order
        conditions = {}
        for i, key in ipairs({ self:primary_keys() }) do
            conditions[key] = (select(i, ...))
        end
    end
    if type(conditions) == 'table' then
        for _, column in ipairs(self:columns()) do
            local value = conditions[column.column_name]
            local fits = fits_type[column.data_type]
            if fits and (type(value) == 'string' or type(value) == 'number'
                    or type(value) == 'boolean') and not fits(value) then
                return nil
            end
        end
    end
    return lapis_find(self, ...)
end

-- TODO: This does not actually autoload the models
-- In the meantime, we will require them manually
-- return require("lapis.util").autoload("models")

package.loaded.BannedIPs = require("models.banned_ips")
package.loaded.CollectionMemberships = require("models.collection_memberships")
package.loaded.Collections = require("models.collections" )
package.loaded.FeaturedCollections = require("models.featured_collections")
package.loaded.FlaggedProjects = require("models.flagged_projects")
package.loaded.Followers = require("models.followers" )
package.loaded.Bookmarks = require("models.bookmarks" )
package.loaded.Projects = require("models.projects")
package.loaded.Remixes = require("models.remixes" )
package.loaded.Tokens = require("models.tokes" )
package.loaded.Users = require("models.users" )
