-- Mark class projects utility
-- ===========================
--
-- Sets likely_class_work = true on a user's projects, or on a single
-- project, and propagates the flag to all (transitive) remixes.
--
-- Not meant to be used from Lapis but as a command-line utility.
-- Reads database connection details from the same env vars used by
-- bin/migrate.lua and config.lua.
--
-- Usage:
--   lua bin/mark-class-projects.lua --user <username>
--   lua bin/mark-class-projects.lua --project <project_id>
--
-- Copyright (C) 2026 by Bernat Romagosa and Michael Ball
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.

local pgmoon = require('pgmoon')

local usage = [[
Usage:
  lua bin/mark-class-projects.lua --user <username>
  lua bin/mark-class-projects.lua --project <project_id>
]]

local mode, value
local i = 1
while i <= #arg do
    local a = arg[i]
    if a == '--user' or a == '-u' then
        mode = 'user'
        value = arg[i + 1]
        i = i + 2
    elseif a == '--project' or a == '-p' then
        mode = 'project'
        value = arg[i + 1]
        i = i + 2
    elseif a == '--help' or a == '-h' then
        print(usage)
        os.exit(0)
    else
        print('Unknown argument: ' .. tostring(a))
        print(usage)
        os.exit(1)
    end
end

if not mode or not value or value == '' then
    print(usage)
    os.exit(1)
end

if mode == 'project' then
    value = tonumber(value)
    if not value then
        print('--project expects a numeric project id')
        os.exit(1)
    end
end

local db = pgmoon.new({
    host = os.getenv('DATABASE_HOST') or '127.0.0.1',
    port = os.getenv('DATABASE_PORT') or '5432',
    database = os.getenv('DATABASE_NAME') or 'snapcloud',
    user = os.getenv('DATABASE_USERNAME') or 'cloud',
    password = os.getenv('DATABASE_PASSWORD') or 'snap-cloud-password'
})

assert(db:connect())

-- Build the seed set: projects we are explicitly marking as class work.
local seed_query
if mode == 'user' then
    seed_query =
        'SELECT id FROM projects WHERE username = ' ..
            db:escape_literal(value)
else
    seed_query =
        'SELECT id FROM projects WHERE id = ' ..
            db:escape_literal(value)
end

-- Mark seed projects, then walk the remix tree marking every descendant.
-- The recursive CTE follows remixes.original_project_id -> remixed_project_id,
-- so a remix of a remix of a seed is also caught.
local update_sql = [[
WITH RECURSIVE seed AS (
    ]] .. seed_query .. [[

),
descendants AS (
    SELECT id FROM seed
    UNION
    SELECT r.remixed_project_id
    FROM remixes r
    INNER JOIN descendants d ON d.id = r.original_project_id
)
UPDATE projects
SET likely_class_work = true
WHERE id IN (SELECT id FROM descendants)
  AND likely_class_work = false
RETURNING id
]]

local result, err = db:query(update_sql)
if not result then
    print('Update failed: ' .. tostring(err))
    os.exit(1)
end

local updated = #result
local seed_result, seed_err = db:query(seed_query)
if not seed_result then
    print('Could not count seed projects: ' .. tostring(seed_err))
    os.exit(1)
end

if mode == 'user' then
    print(
        'User ' .. value .. ': ' .. #seed_result ..
            ' owned project(s); ' .. updated ..
            ' project(s) newly marked likely_class_work=true ' ..
            '(including remix descendants).'
    )
else
    if #seed_result == 0 then
        print('No project found with id ' .. value)
        os.exit(1)
    end
    print(
        'Project ' .. value .. ' and its remix descendants: ' ..
            updated .. ' project(s) newly marked likely_class_work=true.'
    )
end
