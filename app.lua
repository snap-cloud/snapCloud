-- Snap Cloud
-- ============

local lapis = require 'lapis'
local app = lapis.Application()
local db = require 'lapis.db'
local app_helpers = require 'lapis.application'
local capture_errors = app_helpers.capture_errors_json
local yield_error = app_helpers.yield_error
local validate = require 'lapis.validate'
local bcrypt = require 'bcrypt'
local Model = require('lapis.db.model').Model
local util = require('lapis.util')
local respond_to = require('lapis.application').respond_to


-- Packaging everything so it can be accessed from other modules

package.loaded.app = app
package.loaded.db = db
package.loaded.app_helpers = app_helpers
package.loaded.capture_errors = capture_errors
package.loaded.yield_error = yield_error
package.loaded.validate = validate
package.loaded.bcrypt = bcrypt
package.loaded.Model = Model
package.loaded.util = util
package.loaded.respond_to = respond_to


-- This module only takes care of the index endpoint

app:get('/', function(self)
    return { redirect_to = self:build_url('static/index.html') }
end)
    
-- Other application aspects are spread over several modules

require 'api'

return app
