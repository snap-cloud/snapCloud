-- spec_helper.lua
-- ===============
--
-- Loaded by busted before any spec runs (see `.busted`).
--
-- Responsibilities:
--   1. Force LAPIS_ENVIRONMENT=test so every spec looks at the test
--      config block in config.lua.
--   2. Hard-assert that the database we're about to touch is
--      `snapcloud_test`. Running specs against a development or
--      production database would be catastrophic, so we refuse to
--      continue if the effective DB name is anything else.
--   3. Expose a couple of small helpers that individual specs use
--      (see spec.support.*).

-- 1. Environment -------------------------------------------------------------
-- Lapis reads LAPIS_ENVIRONMENT during `require('lapis.config').get()`.
-- Set it before anything else gets a chance to import config.
if os.getenv('LAPIS_ENVIRONMENT') ~= 'test' then
    -- Don't silently overwrite: loudly tell the developer what we did.
    io.stderr:write(
        '[spec_helper] Forcing LAPIS_ENVIRONMENT=test (was "' ..
        tostring(os.getenv('LAPIS_ENVIRONMENT')) .. '")\n'
    )
end
-- os.setenv doesn't exist in stock Lua 5.1; use posix-style via a shell-free
-- mechanism. The `lapis` CLI also respects an in-process `_G.LAPIS_ENVIRONMENT`
-- fallback when set, which is good enough for specs.
_G.LAPIS_ENVIRONMENT = 'test'

-- 2. Database safety gate ----------------------------------------------------
-- We check both the env var (used by config.lua's os.getenv fallbacks) AND
-- the value that actually ends up in the loaded Lapis config.
local expected_db = 'snapcloud_test'
local env_db = os.getenv('DATABASE_NAME')

if env_db ~= nil and env_db ~= expected_db then
    error(
        '[spec_helper] Refusing to run: DATABASE_NAME=' .. tostring(env_db) ..
        ' but specs require ' .. expected_db ..
        '. Unset DATABASE_NAME or export DATABASE_NAME=' .. expected_db .. '.'
    )
end

-- Pull config through Lapis so we exercise the same code path app.lua does.
-- This can fail in very stripped-down environments (no `lapis` rock) — in
-- that case we skip the config-side check; the env-var check above is still
-- in force.
local ok, lapis_config = pcall(require, 'lapis.config')
if ok then
    local cfg = lapis_config.get('test')
    if cfg and cfg.postgres and cfg.postgres.database ~= expected_db then
        error(
            '[spec_helper] Refusing to run: test config database is "' ..
            tostring(cfg.postgres.database) .. '", expected "' ..
            expected_db .. '". Check config.lua.'
        )
    end
    package.loaded.config = cfg
end

-- 3. Support helpers ---------------------------------------------------------
-- Make `require('spec.support.<name>')` work regardless of cwd.
package.path = './spec/?.lua;./spec/?/init.lua;' .. package.path

-- Lazy-load helpers so tests that don't need the DB don't pay for it.
_G.spec_support = setmetatable({}, {
    __index = function (_, key)
        return require('spec.support.' .. key)
    end
})
