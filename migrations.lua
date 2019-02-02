-- Database migrations
-- ===================
--
-- Add a new migration with the key 'YYYY-MM-DD:X'
-- Where X is a value [0-9]
-- NOTES:
-- use _at for timestamps, and always add {timezone = true}
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

local schema = require("lapis.db.schema")
local types = schema.types

return {
    -- TODO: We will eventually create migrations for the other tables.

    -- Create Collections and CollectionMemberships
    ['2019-01-04:0'] = function()
        schema.create_table("collections", {
            { 'id', types.serial({primary_key = true}) },
            { 'name', types.text },
            { 'creator_id', types.foreign_key },
            { 'created_at', types.time({timezone = true}) },
            { 'updated_at', types.time({timezone = true}) },
            { 'description', types.text({null = true}) },
            { 'published', types.boolean },
            { 'published_at', types.time({timezone = true, null = true}) },
            { 'shared', types.boolean },
            { 'shared_at', types.time({timezone = true, null = true}) },
            { 'thumbnail_id', types.foreign_key({null = true}) }
        })
        schema.create_index('collections', 'creator_id')

        schema.create_table("collection_memberships", {
            { 'id', types.serial({primary_key = true}) },
            { 'collection_id', types.foreign_key },
            { 'project_id', types.foreign_key },
            { 'created_at', types.time({timezone = true}) },
            { 'updated_at', types.time({timezone = true}) }
        })
        schema.create_index('collection_memberships', 'collection_id')
        schema.create_index('collection_memberships', 'project_id')
    end,

    -- Update CollectionMemberships to store a user
    ['2019-01-29:0'] = function()
        schema.add_column(
            'collection_memberships', 'user_id', types.foreign_key
        )
        schema.create_index('collection_memberships',
                            'collection_id', 'project_id', 'user_id',
                            { unique = true })
    end
}
