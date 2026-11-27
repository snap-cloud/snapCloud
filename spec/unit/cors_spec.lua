-- spec/unit/cors_spec.lua
-- =======================
--
-- Sanity-check the CORS allow-list. This doesn't exercise the HTTP path —
-- it just verifies that entries of interest are present and that the table
-- has a predictable shape. Protects against accidental deletions.

local domain_allowed = require('cors')

describe('cors', function ()

    it('returns a table', function ()
        assert.are.equal('table', type(domain_allowed))
    end)

    it('allows snap.berkeley.edu', function ()
        assert.is_true(domain_allowed['snap.berkeley.edu'])
    end)

    it('allows localhost for development', function ()
        assert.is_true(domain_allowed['localhost'])
    end)

    it('does not allow an arbitrary unknown domain', function ()
        assert.is_nil(domain_allowed['not-a-real-snap-partner.example'])
    end)

end)
