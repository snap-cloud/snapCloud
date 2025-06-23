-- Database migrations
-- ===================
--
-- Run migrations by running bin/lapis-migrate
--
-- Do not modify a migration once it has been run or commited!
-- To change what a migration does, create a new one.
--
-- Use `lapis generate migration` to scaffold a new migration.
-- NOTES:
-- use _at for timestamps, and always add { timezone = true }
--
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types

-- You MUST recreate the views modifying the users table.
local update_user_views = function ()
    db.query([[
        CREATE OR REPLACE VIEW active_users AS (
            SELECT * FROM users WHERE deleted is null
        )
    ]])
    db.query([[
        CREATE OR REPLACE VIEW deleted_users AS (
            SELECT * FROM users WHERE deleted is not null
        )
    ]])
end

local update_project_views = function ()
    db.query([[
        CREATE OR REPLACE VIEW active_projects AS (
            SELECT * FROM projects WHERE deleted is null
        )
    ]])
    db.query([[
        CREATE OR REPLACE VIEW deleted_projects AS (
            SELECT * FROM projects WHERE deleted is not null
        )
    ]])
end

return {
    -- Create Collections and CollectionMemberships
    ['2019-01-04:0'] = function ()
        schema.create_table('collections', {
            { 'id', types.serial({ primary_key = true }) },
            { 'name', types.text },
            { 'creator_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            { 'description', types.text({ null = true }) },
            { 'published', types.boolean },
            { 'published_at', types.time({ timezone = true, null = true }) },
            { 'shared', types.boolean },
            { 'shared_at', types.time({ timezone = true, null = true }) },
            { 'thumbnail_id', types.foreign_key({ null = true }) }
        })
        schema.create_index('collections', 'creator_id')

        schema.create_table('collection_memberships', {
            { 'id', types.serial({ primary_key = true }) },
            { 'collection_id', types.foreign_key },
            { 'project_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })
        schema.create_index('collection_memberships', 'collection_id')
        schema.create_index('collection_memberships', 'project_id')
    end,

    -- Update CollectionMemberships to store a user
    ['2019-01-29:0'] = function ()
        schema.add_column(
            'collection_memberships', 'user_id', types.foreign_key
        )
        schema.create_index('collection_memberships',
                            'collection_id', 'project_id', 'user_id',
                            { unique = true })
    end,
    -- Create and views for handling deleted items.
    ['2019-02-01:0'] = function ()
        schema.add_column('users',
                          'deleted',
                          types.time({ timezone = true, null = true }))
        update_user_views()

        schema.add_column('projects',
                          'deleted',
                          types.time({ timezone = true, null = true }))
        update_project_views()
    end,

    -- Add an editor_ids[] field to collections
    ['2019-02-04:0'] = function ()
        schema.add_column(
            'collections',
            'editor_ids',
            types.foreign_key({ array = true, null = true })
        )
    end,

    -- Add a table to store spambot IPs and ban them
    ['2019-02-05:0'] = function ()
        schema.create_table("banned_ips", {
            { 'ip', types.text({ primary_key = true }) },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            { 'offense_count', types.integer, { default = 1 } }
        })
    end,

    ['2020-10-22:0'] = function ()
        schema.add_column('users', 'unique_email', types.text({ null = true, unique = true }))
        -- We use an index on *non-unique* emails to be able to search related accounts.
        -- We will rarely query by unique_email and thus no index is necessary.
        schema.create_index('users', 'email', { unique = false })
        update_user_views()
    end,

    -- Update Collections to include a "free for all" flag
    ['2020-11-03:0'] = function ()
        schema.add_column(
            'collections',
            'free_for_all',
            types.boolean
        )
        -- The "flagged" collection is free for all
        db.update(
            'collections',
            { free_for_all = true },
            { id = 0 }
        )
    end,

    -- Create a FlaggedProjects table
    ['2020-11-09:0'] = function ()
        schema.create_table("flagged_projects", {
            { 'id', types.serial({ primary_key = true }) },
            { 'flagger_id', types.foreign_key },
            { 'project_id', types.foreign_key },
            { 'reason', types.text },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) }
        })

        -- One flag per user and project
        schema.create_index('flagged_projects',
                            'flagger_id', 'project_id',
                            { unique = true })
    end,

    -- Add a notes column to FlaggedProjects
    ['2020-11-10:0'] = function ()
        schema.add_column(
            'flagged_projects',
            'notes',
            types.text({ null = true })
        )
    end,

    -- Create a FeaturedCollections table
    ['2022-08-16:0'] = function ()
        schema.create_table("featured_collections", {
            { 'collection_id', types.foreign_key },
            { 'page_path', types.text },
            -- type is a free-text field we can use to add information about a
            -- collection in a page, such as "totm" or "pick 5"
            { 'type', types.text },
            { 'order', types.integer },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            'PRIMARY KEY (collection_id, page_path)'
        })
    end,

    -- Populate the FeaturedCollections table with the default carousels
    ['2022-08-17:0'] = function ()
        -- Example collections
        local ids = db.query([[
            SELECT id FROM collections
                WHERE creator_id =
                    (SELECT id FROM users WHERE username = 'snapcloud' LIMIT 1)
                AND name IN
                    ('Fractals', 'Animations', 'Art Projects',
                    'Science Projects', 'Music', 'Simulations', 'Games',
                    'Computer Science', 'Maths');
        ]])
        for _, entry in pairs(ids) do
            -- Examples page
            db.query([[
                INSERT INTO featured_collections
                    (collection_id, page_path, type, created_at, updated_at)
                VALUES
                    (?, 'examples', 'example', now()::timestamp,
                        now()::timestamp)
            ]], entry.id)
            -- Front page
            db.query([[
                INSERT INTO featured_collections
                    (collection_id, page_path, type, created_at, updated_at)
                VALUES
                    (?, 'index', 'example', now()::timestamp, now()::timestamp)
            ]], entry.id)
        end
        -- Events page
        ids = db.query([[
            SELECT id FROM collections
                WHERE creator_id =
                    (SELECT id FROM users WHERE username = 'snapcloud' LIMIT 1)
                AND name LIKE 'Snap%20%'
            ]])
        for _, entry in pairs(ids) do
            db.query([[
                INSERT INTO featured_collections
                    (collection_id, page_path, type, created_at, updated_at)
                VALUES
                    (?, 'events', 'event', now()::timestamp, now()::timestamp)
            ]], entry.id)
        end
        -- Featured collection
        db.query([[
            INSERT INTO featured_collections
                (collection_id, page_path, type, created_at, updated_at)
            VALUES (
                (SELECT id FROM collections
                    WHERE name = 'Featured'
                    AND creator_id = (
                        SELECT id FROM users
                        WHERE username = 'snapcloud' LIMIT 1
                    )
                ),
                'index',
                'featured',
                now()::timestamp,
                now()::timestamp
            )
        ]])
        -- Left for the maintainer is to feature the current TOTM and latest
        -- event, if it applies
    end,

    -- Create a Followers table
    ['2022-08-18:0'] = function ()
        schema.create_table("followers", {
            { 'follower_id', types.foreign_key },
            { 'followed_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            'PRIMARY KEY (follower_id, followed_id)'
        })
    end,

    -- Add a bad_flags column to users, to store the times they've flagged a
    -- legitimate project
    ['2022-09-16:0'] = function ()
        schema.add_column(
            'users',
            'bad_flags',
            types.integer({ default = 0 })
        )
        update_user_views()
    end,

    -- Add columns to users to support teacher accounts.
    ['2023-03-14:0'] = function()
        -- this is likely temporary, but is a starting point.
        schema.add_column(
            'users',
            'is_teacher',
            types.boolean({ default = false })
        )
        schema.add_column(
            'users',
            'creator_id',
            types.foreign_key({ null = true })
        )
    end,

    ['2023-03-14:1'] = function()
        update_user_views()
    end,

    -- Add a specific student role.
    -- Ordering likeky shouldn't be relied upon, but this is nice to have.
    ['1683536418'] = function()
        db.query([[
            ALTER TYPE snap_user_role ADD VALUE 'student' BEFORE 'standard';
        ]])
    end,

    -- Create a Bookmarks table
    ['2025-02-06:0'] = function ()
        schema.create_table('bookmarks', {
            { 'bookmarker_id', types.foreign_key },
            { 'project_id', types.foreign_key },
            { 'created_at', types.time({ timezone = true }) },
            { 'updated_at', types.time({ timezone = true }) },
            'PRIMARY KEY (bookmarker_id, project_id)'
        })
    end,

    -- Add a likely_class_work column to projects
    -- Add last_login and session_count column to users
    ['2025-06-18:0'] = function ()
        schema.add_column(
            'users',
            'last_login_at',
            types.time({ timezone = true, null = true })
        )

        schema.add_column(
            'users',
            'session_count',
            types.integer({ default = 0 })
        )

        -- Add likely_class_work column to projects
        schema.add_column(
            'projects',
            'likely_class_work',
            types.boolean({ default = false })
        )

        -- Add an index for likely_class_work
        schema.create_index('projects', 'likely_class_work')

        update_user_views()
        update_project_views()
    end,
}
