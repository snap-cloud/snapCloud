-- Database migrations.
-- Add a new migration with the key YYYYYMMDDX
-- Where X is a value [0-9]
-- NOTES:
-- use _at for timestamps, and always add {timezone = true}

local schema = require("lapis.db.schema")

local types = schema.types

return {
    -- TODO: We will eventually create migrations for the other tables.

    [20190140] = function()
        schema.create_table("collections", {
            { 'id', types.serial({primary_key = true}) },
            { 'name', types.text },
            { 'slug', types.text },
            { 'creator_id', types.foregin_key },
            { 'created_at', types.time({timezone = true}) },
            { 'updated_at', types.time({timezone = true}) },
            { 'description', types.text({null = true}) },
            { 'published', types.boolean },
            { 'published_at', types.time({timezone = true, null = true}) },
            { 'shared', types.boolean },
            { 'shared_at', types.time({timezone = true, null = true}) },
            { 'thumbnail_id', types.foregin_key({null = true}) }
        })
        schema.create_index('collections', 'creator_id')
        schema.create_index('collections', 'creator_id', 'slug')

        schema.create_table("collection_memberships", {
            { 'id', types.serial({primary_key = true}) },
            { 'collection_id', types.foregin_key },
            { 'project_id', types.foregin_key },
            { 'created_at', types.time({timezone = true}) },
            { 'updated_at', types.time({timezone = true}) }
        })
        schema.create_index('collection_memberships', 'collection_id')
        schema.create_index('collection_memberships', 'project_id')
    end
}
