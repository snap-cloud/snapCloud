-- spec/support/db_helper.lua
-- =========================
--
-- Thin wrapper around lapis.db that:
--   * Re-asserts the snapcloud_test guard at query time (defense in depth
--     against someone monkey-patching config mid-run).
--   * Offers `truncate_all()` so each test gets a clean slate without
--     dropping and re-creating the schema.
--
-- This is only useful in a real Postgres environment — i.e. the `busted`
-- job in CI, or `make test` on a developer machine that has the
-- snapcloud_test database set up. Pure-Lua specs don't need it.

local M = {}

local function ensure_test_db()
    local cfg = package.loaded.config or require('lapis.config').get('test')
    if not cfg or not cfg.postgres then
        error('[db_helper] Could not resolve Lapis test config.')
    end
    if cfg.postgres.database ~= 'snapcloud_test' then
        error(
            '[db_helper] Aborting DB operation: configured database is "' ..
            tostring(cfg.postgres.database) ..
            '", expected "snapcloud_test".'
        )
    end
end

function M.db()
    ensure_test_db()
    return require('lapis.db')
end

-- Tables that hold per-test state. Order doesn't matter for TRUNCATE ...
-- CASCADE, but we list them explicitly so nothing unexpected gets wiped.
M.tables = {
    'bookmarks',
    'collection_memberships',
    'collections',
    'featured_collections',
    'flagged_projects',
    'followers',
    'remixes',
    'tokens',
    'projects',
    'users',
    'banned_ips',
}

-- Wipe data from every table listed above. Sequences are reset so that
-- fixture-generated ids stay predictable across test runs.
function M.truncate_all()
    local db = M.db()
    db.query(
        'TRUNCATE TABLE ' ..
        table.concat(M.tables, ', ') ..
        ' RESTART IDENTITY CASCADE'
    )
end

-- Convenience: run `fn()` inside a transaction that is always rolled back.
-- Great for specs that want isolation without paying for a TRUNCATE.
function M.with_rollback(fn)
    local db = M.db()
    db.query('BEGIN')
    local ok, err = pcall(fn)
    db.query('ROLLBACK')
    if not ok then error(err) end
end

return M
