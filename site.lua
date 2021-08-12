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
    local query = 'where ispublished and username not in ' ..
        '(select username from deleted_users)'
    -- Apply where clauses
    if self.params.matchtext then
        query = query ..
        db.interpolate_query(
        ' and (projectname ILIKE ? or notes ILIKE ?)',
        self.params.matchtext,
        self.params.matchtext
        )
    end

    -- Apply project name filter to hide projects with typical
    -- BJC or Teals names.
    if self.params.filtered then
        query = query .. db.interpolate_query(course_name_filter())
    end

    local paginator =
        Projects:paginated(
        query .. ' order by firstpublished desc',
        { per_page = 15 }
    )

   self.paginator = paginator
   self.pageNumber = 1
   self.class = 'projects'
   self.title = 'Latest Projects'

    return { render = 'grid' }
end)
