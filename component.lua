-- Component module
-- ================
--
-- A generic, transparent, AJAX-updatable web component.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2021 by Bernat Romagosa and Michael Ball
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


local util = package.loaded.util
local etlua = require 'etlua'
local app = package.loaded.app
local component = { actions = {}, queries = {} }

local actions = component.actions

local render = function (template_path, options)
    local template_path = template_path:gsub('%.','/') .. '.etlua'
    local template = ''
    local file = io.open(template_path, 'r')
    if (file) then
        template = file:read('*all')
        file:close()
    end
    options.internal = true
    return etlua.render(template, options)
end

app:post(
    '/update_component/:component_id/:selector(/:params_json)',
    function (self)
        ngx.req.read_body()
        local component = util.from_json(ngx.req.get_body_data())

        -- run the action associated to this particular component and selector,
        -- from the actions table
        actions[component.path][self.params.selector](
            self.session,
            component.data,
            self.params.params_json and
                util.from_json(self.params.params_json) or
                nil
        )

        -- return the compiled component, plus the new data for the component
        return jsonResponse({
            data = component,
            html = render(
                'views.components.' .. component.path,
                {
                    data = component.data,
                    run = 'update_' .. component.id,
                    render = render
                }
            )
        })
    end
)

function component:new (path)
    return {
        path = path,
        id = 'lps_' .. (math.floor(math.random()*1000000000) + os.time()),
        data = {}
    }
end

return component
