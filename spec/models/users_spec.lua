-- spec/models/users_spec.lua
-- ==========================
--
-- Integration-ish spec for the Users model. Requires a running
-- `snapcloud_test` Postgres database loaded with db/schema.sql. If the
-- DB isn't reachable the spec is marked `pending` so local unit-test
-- runs stay green.

local ok_db, db_helper = pcall(require, 'spec.support.db_helper')

-- Try to ping the database. If we can't, emit a `pending` so the run
-- still reports a useful status instead of a hard failure.
local function db_reachable()
    if not ok_db then return false, 'db_helper failed to load' end
    local ok, err = pcall(function ()
        db_helper.db().query('SELECT 1')
    end)
    if not ok then return false, tostring(err) end
    return true
end

describe('models.users', function ()
    local reachable, reason = db_reachable()

    if not reachable then
        pending('requires a running snapcloud_test database (' ..
            tostring(reason) .. ')')
        return
    end

    local factories = require('spec.support.factories')

    before_each(function ()
        db_helper.truncate_all()
        factories.reset()
    end)

    it('persists and round-trips a user', function ()
        local created = factories.user({ username = 'alice_test' })
        assert.are.equal('alice_test', created.username)

        require('models')
        local fetched = package.loaded.Users:find({ username = 'alice_test' })
        assert.is_not_nil(fetched)
        assert.are.equal('alice_test', fetched.username)
    end)

    it('defaults role to standard', function ()
        local u = factories.user()
        assert.are.equal('standard', u.role)
    end)

    it('role helpers report correctly', function ()
        local admin = factories.user({ role = 'admin' })
        assert.is_true(admin:isadmin())
        assert.is_true(admin:has_min_role('standard'))

        local student = factories.user({ role = 'student' })
        assert.is_true(student:is_student())
        assert.is_false(student:isadmin())
    end)

end)
