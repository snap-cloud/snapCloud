-- Project controller
-- ==================
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

local Projects = package.loaded.Projects
local Collections = package.loaded.Collections
local Users = package.loaded.Users
local db = package.loaded.db
local disk = package.loaded.disk

ProjectController = {
    fetch = function (self)
        local data = self.params.data
        local query = [[WHERE ispublished AND NOT EXISTS(
            SELECT 1 FROM deleted_users WHERE
            username = active_projects.username LIMIT 1)]] ..
            db.interpolate_query(course_name_filter())

        -- query can hold a paginator or an SQL query
        local paginator = Projects:paginated(
                 query ..
                    (data.search_term and (db.interpolate_query(
                        ' AND (projectname ILIKE ? OR notes ILIKE ?)',
                        '%' .. data.search_term .. '%',
                        '%' .. data.search_term .. '%')
                    ) or '') ..
                    (data.order and (' ORDER BY ' .. data.order) or ''),
                {
                    per_page = data.per_page or 15,
                    fields = data.fields or '*'
                }
            )
        if not data.ignore_page_count then
            data.num_pages = paginator:num_pages()
        end
        data.items = paginator:get_page(data.page_number)
        disk:process_thumbnails(data.items)
        self.data = data
    end,
    page = function (self)
    end
}
