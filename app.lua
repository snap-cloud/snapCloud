-- Snap Cloud
-- ==========
--
-- a cloud backend for Snap!
-- written by Bernat Romagosa
--
-- Copyright (C) 2017 by Bernat Romagosa
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.


-- Packaging everything so it can be accessed from other modules

local lapis = require 'lapis'
package.loaded.app = lapis.Application()
package.loaded.db = require 'lapis.db'
package.loaded.app_helpers = require 'lapis.application'
package.loaded.json_params = package.loaded.app_helpers.json_params
package.loaded.capture_errors = package.loaded.app_helpers.capture_errors_json
package.loaded.yield_error = package.loaded.app_helpers.yield_error
package.loaded.validate = require 'lapis.validate'
package.loaded.bcrypt = require 'bcrypt'
package.loaded.Model = require('lapis.db.model').Model
package.loaded.util = require('lapis.util')
package.loaded.respond_to = require('lapis.application').respond_to
package.loaded.cached = require('lapis.cache').cached

local app = package.loaded.app


-- Database abstractions

package.loaded.Users = package.loaded.Model:extend('users', {
    primary_key = { 'username' }
})

package.loaded.Projects = package.loaded.Model:extend('projects', {
    primary_key = { 'username', 'projectname' }
})


-- Before filter

app:before_filter(function (self)
    -- unescape all parameters
    for k,v in pairs(self.params) do
        self.params[k] = package.loaded.util.unescape(v)
    end

    -- Set Access Control header
    -- FIXME change to actual domain in production
    local origin = ngx.var.http_referer and ngx.var.http_referer:match('^(%w+://[^/]+)') or 'http://localhost:8080'
    self.res.headers['Access-Control-Allow-Origin'] = origin
    self.res.headers['Access-Control-Allow-Credentials'] = 'true'

end)


-- This module only takes care of the index endpoint

app:get('/', function(self)
    return { redirect_to = self:build_url('static/index.html') }
end)
    

-- The API is implemented in the api.lua file

require 'api'

return app
