-- spec/support/factories.lua
-- ==========================
--
-- Tiny factory helpers for creating test records without hand-writing
-- INSERT statements in every spec. Inspired by FactoryBot / ex_machina.
--
-- Usage:
--   local factories = require('spec.support.factories')
--   local user = factories.user({ username = 'alice' })
--   local project = factories.project({ username = user.username })
--
-- Each factory:
--   * Fills in sensible defaults so callers only pass what they care about.
--   * Uses a monotonically-increasing sequence to keep names/ids unique
--     across a single spec run.
--   * Delegates to the real Lapis model so model callbacks run normally.

local factories = {}

local seq = 0
local function next_seq()
    seq = seq + 1
    return seq
end

-- Reset the sequence between test files / describe blocks.
function factories.reset()
    seq = 0
end

-- Merge `overrides` on top of `defaults`, non-destructively.
local function merge(defaults, overrides)
    overrides = overrides or {}
    for k, v in pairs(overrides) do defaults[k] = v end
    return defaults
end

-- Users -----------------------------------------------------------------
function factories.user(overrides)
    -- Require models lazily: some specs never touch the DB.
    require('models')
    local Users = package.loaded.Users
    local n = next_seq()
    return Users:create(merge({
        username = 'test_user_' .. n,
        email = 'test_user_' .. n .. '@example.com',
        -- Matches the schema default so it's safe in any state.
        role = 'standard',
        verified = true,
        created = require('lapis.db').raw('NOW()'),
        salt = 'test-salt-' .. n,
        -- In real code passwords are pre-hashed on the client and then
        -- re-hashed with the salt. For tests we just need something there.
        password = 'not-a-real-password',
    }, overrides))
end

-- Projects --------------------------------------------------------------
function factories.project(overrides)
    require('models')
    local Projects = package.loaded.Projects
    local n = next_seq()
    overrides = overrides or {}
    -- A project needs an owning user; create one if the caller didn't
    -- pass a username.
    if not overrides.username then
        overrides.username = factories.user().username
    end
    return Projects:create(merge({
        projectname = 'Test Project ' .. n,
        ispublic = false,
        ispublished = false,
        notes = 'Created by spec/support/factories.lua',
        created = require('lapis.db').raw('NOW()'),
        lastupdated = require('lapis.db').raw('NOW()'),
    }, overrides))
end

-- Collections -----------------------------------------------------------
function factories.collection(overrides)
    require('models')
    local Collections = package.loaded.Collections
    local n = next_seq()
    overrides = overrides or {}
    if not overrides.creator_id then
        overrides.creator_id = factories.user().id
    end
    return Collections:create(merge({
        name = 'Test Collection ' .. n,
        description = 'Created by spec/support/factories.lua',
        published = false,
        shared = false,
        created_at = require('lapis.db').raw('NOW()'),
        updated_at = require('lapis.db').raw('NOW()'),
    }, overrides))
end

return factories
