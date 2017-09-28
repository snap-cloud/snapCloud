-- Snap Cloud
-- ============


-- Packaging everything so it can be accessed from other modules

local lapis = require 'lapis'
package.loaded.app = lapis.Application()
package.loaded.db = require 'lapis.db'
package.loaded.app_helpers = require 'lapis.application'
package.loaded.capture_errors = package.loaded.app_helpers.capture_errors_json
package.loaded.yield_error = package.loaded.app_helpers.yield_error
package.loaded.validate = require 'lapis.validate'
package.loaded.bcrypt = require 'bcrypt'
package.loaded.Model = require('lapis.db.model').Model
package.loaded.util = require('lapis.util')
package.loaded.respond_to = require('lapis.application').respond_to

local app = package.loaded.app


-- Before filter

app:before_filter(function (self)
    -- unescape all parameters
    for k,v in pairs(self.params) do
        self.params[k] = package.loaded.util.unescape(v)
    end

    -- Set Access Control header
    self.res.headers['Access-Control-Allow-Origin'] = 'http://localhost:8081'
    self.res.headers['Access-Control-Allow-Credentials'] = 'true'

    if (not self.session.username) then
        self.session.username = ''
    end
end)


-- This module only takes care of the index endpoint

app:get('/', function(self)
    return { redirect_to = self:build_url('static/index.html') }
end)
    

-- The API is implemented in the api.lua file

require 'api'

return app
