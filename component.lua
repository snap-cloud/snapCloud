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
--
--
-- HowTo
-- =====
--
-- Create a component:
--
-- 1) Create an etlua template in views/components. For example: counter.etlua.
-- 2) All data should be accessed via the Lua data object. For example:
--    <span><%= data.current_number %></span>
-- 3) Lua server-side actions should be called in JS source like this:
--    <%run%>('lua-selector', [param1, param2])
--    where lua-selector is the actual selector in the actions table in this
--    module, for example:
--    <button onclick="<%run%>('change_by', 1)">+</button>
--    <button onclick="<%run%>('change_by', -1)">-</button>
--
-- Define actions for the component:
--
-- 4) Add functions for each selector into the actions table in this module.
--    For example:
--      actions['counter'] = {
--        change_by = function (data, amount)
--          data.number = data.number + amount
--        end
--      }
--
-- Use a component in an etlua template:
--
-- 5) Include the component anywhere in your template like this:
--
-- <% render(component_html('component-name', { key = value })) %>
--
-- , for example:
--
-- <% render(component_html('counter', { current_number = 10 })) %>
--
-- Add a route for the component-using template:
--
-- 6) Before rendering it, enable components for the template:
--
-- app:get('/my-route', function (self)
--      enable_components(self)
--      return { render = 'a-template-that-uses-components' }
-- end)
--
-- A Complete Example
-- ==================
--
-- For a complete example, see the views/multicounter.etlua template and the
-- views/components/counter.etlua component. To test it, add this code to your
-- route handler:
--
-- local component = require 'component'
--
-- app:get('/multicounter', function (self)
--    component:enable_components(self)
--    return { render = 'multicounter' }
-- end)
--
-- component.actions['counter'] = {
--    change_by = function (data, params)
--        data.number = data.number + params[1]
--    end
--}

local util = package.loaded.util
local etlua = require "etlua"
local app = package.loaded.app
local component = { actions = {} }

local actions = component.actions

app:post(
    '/update_component/:component_id/:selector(/:params_json)',
    function (self)
        ngx.req.read_body()
        local component = util.from_json(ngx.req.get_body_data())

        -- run the action associated to this particular component and selector,
        -- from the actions table
        actions[component.path][self.params.selector](
            component.data,
            self.params.params_json and
                util.from_json(self.params.params_json) or
                nil
        )

        -- find the component template and read it all into memory
        local template = ''
        local file = io.open(
            'views/components/' .. component.path:gsub("%.", "/") .. '.etlua',
            'r'
        )
        if (file) then
            template = file:read("*all")
            file:close()
        end

        -- return the compiled component, plus the new data for the component
        return jsonResponse({
            data = component,
            html = etlua.render(
                template,
                { data = component.data, run = 'update_' .. component.id, render = etlua.render }
            )
        })
    end
)


function component:enable_components (self)
    -- add the component_html function for the template to use
    self.component_html = function (self, path, data)
        local component = {
            path = path,
            id = 'lps_' .. (math.floor(math.random()*10000000) + os.time()),
            data = data
        }

        return 'views.components.component',
        {
            component = component,
            json = util.to_json(component),
            data = data
        }
    end
end

return component
