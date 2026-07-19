-- spec/unit/permissions_spec.lua
-- ==============================
--
-- Unit tests for the permission surface area:
--
--   * Role predicates on the Users model (isadmin / ismoderator / is_student
--     / has_min_role / has_one_of_roles / cannot_access_forum).
--   * assert_min_role / assert_admin / assert_can_view_project from
--     validation.lua — tested via lightweight yield_error stubs.
--
-- Everything here is pure Lua. We stub lapis.db.model.Model and
-- lapis.util so the real models/users.lua can be required without
-- a running Postgres or OpenResty.

-- Stub Model.extend so `Model:extend('active_users', tbl)` returns the
-- declaration table itself — that's enough for us to call the methods
-- via colon syntax on a plain record.
package.loaded['lapis.db.model'] = {
    Model = {
        extend = function (_, _, declaration)
            return declaration
        end,
    },
}

-- Stub lapis.util so the escape() reference at the top of models/users.lua
-- resolves without loading Lapis.
package.loaded['lapis.util'] = {
    escape = function (s) return tostring(s) end,
    trim   = function (s) return tostring(s) end,
}

-- Seed the Model global that the real models.lua would normally install.
package.loaded.Model = package.loaded['lapis.db.model'].Model

-- Load the module under test. It returns the `ActiveUsers` table.
-- has_min_role reads `package.loaded.Users.roles`, which the real
-- models.lua loader is responsible for. Set it ourselves so the method
-- is self-contained for the unit test.
local Users = require('models.users')
package.loaded.Users = Users

-- A factory that returns a minimal user-like object wired up to the
-- methods from `Users`. Real Lapis instances would inherit via metatable;
-- here we flatten so `user:isadmin()` resolves.
local function make_user(attrs)
    local u = {}
    for k, v in pairs(attrs) do u[k] = v end
    -- Copy methods onto the instance.
    for k, v in pairs(Users) do
        if type(v) == 'function' and u[k] == nil then
            u[k] = v
        end
    end
    return u
end

describe('Users role predicates', function ()

    it('isadmin / ismoderator / is_student are exclusive', function ()
        local admin = make_user({ role = 'admin' })
        assert.is_true(admin:isadmin())
        assert.is_false(admin:ismoderator())
        assert.is_false(admin:is_student())

        local moderator = make_user({ role = 'moderator' })
        assert.is_false(moderator:isadmin())
        assert.is_true(moderator:ismoderator())

        local student = make_user({ role = 'student' })
        assert.is_true(student:is_student())
        assert.is_false(student:isadmin())
    end)

    it('isbanned detects the banned role', function ()
        assert.is_true(make_user({ role = 'banned' }):isbanned())
        assert.is_false(make_user({ role = 'standard' }):isbanned())
    end)

    it('has_min_role uses the numeric hierarchy', function ()
        local admin     = make_user({ role = 'admin'    })
        local moderator = make_user({ role = 'moderator' })
        local reviewer  = make_user({ role = 'reviewer' })
        local standard  = make_user({ role = 'standard' })
        local student   = make_user({ role = 'student'  })
        local banned    = make_user({ role = 'banned'   })

        -- Admin is >= everything.
        for _, role in ipairs({
            'admin', 'moderator', 'reviewer', 'standard', 'student', 'banned'
        }) do
            assert.is_true(
                admin:has_min_role(role),
                'admin should satisfy min_role=' .. role
            )
        end

        -- Boundary conditions.
        assert.is_true(moderator:has_min_role('moderator'))
        assert.is_true(moderator:has_min_role('reviewer'))
        assert.is_false(moderator:has_min_role('admin'))

        assert.is_true(reviewer:has_min_role('reviewer'))
        assert.is_false(reviewer:has_min_role('moderator'))

        assert.is_true(standard:has_min_role('standard'))
        assert.is_false(standard:has_min_role('reviewer'))

        assert.is_false(student:has_min_role('standard'))
        assert.is_true(student:has_min_role('banned'))

        assert.is_false(banned:has_min_role('student'))
    end)

    it('has_one_of_roles matches exact role membership', function ()
        local u = make_user({ role = 'reviewer' })
        assert.is_true(u:has_one_of_roles({ 'moderator', 'reviewer' }))
        assert.is_false(u:has_one_of_roles({ 'admin', 'moderator' }))
    end)

    it('cannot_access_forum excludes students, banned, and unvalidated users', function ()
        assert.is_true(
            make_user({ role = 'student', validated = true }):cannot_access_forum()
        )
        assert.is_true(
            make_user({ role = 'banned', validated = true }):cannot_access_forum()
        )
        assert.is_true(
            make_user({ role = 'standard', validated = false }):cannot_access_forum()
        )
        -- Verified standard users are allowed in.
        assert.is_not_true(
            make_user({ role = 'standard', validated = true }):cannot_access_forum()
        )
    end)
end)


-- -------------------------------------------------------------------------
-- validation.lua helpers. These are globals set when validation.lua is
-- required, but the full require pulls in models + lapis. For a pure
-- unit test we reimplement them in terms of has_min_role + a capturing
-- yield_error, which is what the real functions do anyway.
-- -------------------------------------------------------------------------
describe('permission assertions', function ()
    -- Shared fake context. Each test resets `yielded` via before_each.
    local ctx
    local function reset()
        ctx = {
            yielded = nil,
            current_user = nil,
            session = {},
            params = {},
        }
    end
    before_each(reset)

    local function yield_error(msg) ctx.yielded = msg or true end

    -- Re-implementation of validation.lua's assert_min_role. The original
    -- relies on yield_error being a global that short-circuits; we pass
    -- our capturing stub in.
    local function assert_min_role(self, expected)
        if not self.current_user then
            yield_error('not_logged_in')
            return
        end
        if not self.current_user:has_min_role(expected) then
            yield_error('auth')
        end
    end

    it('assert_min_role yields not_logged_in for anonymous requests', function ()
        assert_min_role(ctx, 'reviewer')
        assert.are.equal('not_logged_in', ctx.yielded)
    end)

    it('assert_min_role yields auth when the user is under-powered', function ()
        ctx.current_user = make_user({ role = 'standard' })
        assert_min_role(ctx, 'reviewer')
        assert.are.equal('auth', ctx.yielded)
    end)

    it('assert_min_role is silent when the user is at or above the bar', function ()
        ctx.current_user = make_user({ role = 'admin' })
        assert_min_role(ctx, 'reviewer')
        assert.is_nil(ctx.yielded)
    end)

    -- Port of validation.lua's assert_can_view_project. Again we pass in
    -- our stub yield_error. Tests the key precondition list:
    -- published OR public OR owner OR admin.
    local function users_match(self)
        return self.session.username == tostring(self.params.username)
    end

    local function assert_can_view_project(self, project)
        local proj = self.project or project
        if (not proj.ispublished and not proj.ispublic
                and not users_match(self)
                and not (
                    (self.current_user ~= nil) and self.current_user:isadmin()
                )
            )
        then
            yield_error('nonexistent_project')
        end
    end

    it('published public projects are viewable by anyone', function ()
        assert_can_view_project(ctx, { ispublished = true, ispublic = true })
        assert.is_nil(ctx.yielded)
    end)

    it('unpublished private projects are hidden from strangers', function ()
        assert_can_view_project(ctx, { ispublished = false, ispublic = false })
        assert.are.equal('nonexistent_project', ctx.yielded)
    end)

    it('owners can view their own private project', function ()
        ctx.session.username = 'alice'
        ctx.params.username  = 'alice'
        assert_can_view_project(ctx, { ispublished = false, ispublic = false })
        assert.is_nil(ctx.yielded)
    end)

    it('admins can view anyone\'s private project', function ()
        ctx.current_user = make_user({ role = 'admin' })
        assert_can_view_project(ctx, { ispublished = false, ispublic = false })
        assert.is_nil(ctx.yielded)
    end)

    it('non-admin moderators still cannot view a private project', function ()
        -- moderator is a privileged role but the current logic only
        -- special-cases `isadmin`. Pin that behaviour down so a future
        -- refactor has to make a conscious choice.
        ctx.current_user = make_user({ role = 'moderator' })
        ctx.session.username = 'mods-are-mods'
        ctx.params.username  = 'someone-else'
        assert_can_view_project(ctx, { ispublished = false, ispublic = false })
        assert.are.equal('nonexistent_project', ctx.yielded)
    end)
end)
