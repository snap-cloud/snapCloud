-- spec/unit/util_spec.lua
-- =======================
--
-- Pure-Lua tests for lib/util.lua. These run with nothing more than
-- `busted` + a Lua 5.1 interpreter — no OpenResty, no Postgres.

-- lib/util.lua reads package.loaded.config at require-time. Stub it so
-- the file doesn't blow up outside of a Lapis process.
package.loaded.config = package.loaded.config or { _name = 'test' }

local util = require('lib.util')

describe('lib.util', function ()

    describe('capitalize', function ()
        it('upper-cases the first character', function ()
            assert.are.equal('Snap', util.capitalize('snap'))
        end)

        it('leaves already-capitalized words alone', function ()
            assert.are.equal('Snap', util.capitalize('Snap'))
        end)

        it('handles the empty string', function ()
            assert.are.equal('', util.capitalize(''))
        end)
    end)

    describe('domain_name', function ()
        it('strips scheme and trailing port', function ()
            assert.are.equal(
                'snap.berkeley.edu',
                util.domain_name('https://snap.berkeley.edu:443')
            )
        end)

        it('returns nil for nil input', function ()
            assert.is_nil(util.domain_name(nil))
        end)

        it('accepts http URLs without a port', function ()
            assert.are.equal(
                'example.com',
                util.domain_name('http://example.com')
            )
        end)
    end)

    describe('escape_html', function ()
        it('escapes the five HTML-significant characters', function ()
            assert.are.equal(
                '&lt;a href=&quot;x&quot;&gt;&amp;&#039;&lt;/a&gt;',
                util.escape_html([[<a href="x">&'</a>]])
            )
        end)

        it('returns nil for nil input', function ()
            assert.is_nil(util.escape_html(nil))
        end)
    end)

    describe('group_by_type', function ()
        it('buckets items by their .type field', function ()
            local grouped = util.group_by_type({
                { type = 'a', id = 1 },
                { type = 'b', id = 2 },
                { type = 'a', id = 3 },
            })
            assert.are.equal(2, #grouped.a)
            assert.are.equal(1, #grouped.b)
            assert.are.equal(1, grouped.a[1].id)
            assert.are.equal(3, grouped.a[2].id)
        end)
    end)

end)
