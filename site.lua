-- Community site module
-- =====================
--
-- Routes for all community website pages. We're in the process of starting to
-- transition the whole site to Lua.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2020 by Bernat Romagosa and Michael Ball
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

local app = package.loaded.app
local capture_errors = package.loaded.capture_errors
local respond_to = package.loaded.respond_to

local Projects = package.loaded.Projects
local db = package.loaded.db

local etlua = require "etlua"
local actions = {}

local util = package.loaded.util

app:enable('etlua')
app.layout = require 'views.layout'

local views = {
    -- Static pages
    'about', 'bjc', 'coc', 'contact', 'credits', 'dmca', 'extensions',
    'materials', 'mirrors', 'offline', 'partners', 'privacy', 'requirements',
    'research', 'snapinator', 'snapp', 'source', 'tos',

    -- Simple pages
    'admin', 'blog', 'change_email', 'change_password', 'delete_user',
    'forgot_password', 'forgot_username', 'login', 'sign_up'
}

for _, view in pairs(views) do
    app:get('/' .. view, function (self)
        return { render = view }
    end)
end

app:get('/test', function (self)
-- This is WAY faster, but fails when using :num_pages because COUNT(*) can't
-- be used with ORDER BY when there's a subquery, for some obscure reason.
--[[    local query = ' WHERE ispublished AND NOT EXISTS( ' ..
        'SELECT 1 FROM deleted_users WHERE ' ..
            'username = active_projects.username LIMIT 1) ' ..
        db.interpolate_query(course_name_filter()) ..
        ' ORDER BY firstpublished DESC'
]]--

    local query = 'WHERE ispublished AND username NOT IN ' ..
        '(SELECT username FROM deleted_users) ' ..
        db.interpolate_query(course_name_filter()) ..
        ' ORDER BY firstpublished DESC'

    self.paginator = Projects:paginated(query, { per_page = 15 })
    self.pageNumber = 1
    self.class = 'projects'
    self.title = 'Latest Projects'
    self.withPaginator = true

    return { render = 'partials.grid' }
end)






app:post('/update_component/:component_id/:selector', function (self)

    ngx.req.read_body()
    local component = util.from_json(ngx.req.get_body_data())

    debug_print(component.path)
    actions[component.path][self.params.selector](component.data)

    local template = ''
    local file = io.open(
        'views/' .. component.path:gsub("%.", "/") .. '.etlua',
        'r'
    )
    if (file) then
        template = file:read("*all")
        file:close()
    end
    return jsonResponse({
        data = component,
        html = etlua.render(
            template,
            { data = component.data, run = 'update_' .. component.id }
        )
    })
end)

function component_html (self, path, data)
    local component = {
        path = path,
        id = 'lps_' .. (math.floor(math.random()*10000000) + os.time()),
        data = data
    }

    return 'views.partials.component', 
        {
            component = component,
            json = util.to_json(component),
            data = data
        }
end

app:get('/multicounter', function (self)
    self.component_html = component_html
    return { render = 'multicounter' }
end)

actions['partials.counter'] = {
    increment = function (data)
        data.number = data.number + 1
    end,
    decrement = function (data)
        data.number = data.number - 1
    end
}

