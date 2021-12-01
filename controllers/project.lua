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
        local query = [[WHERE ispublished AND NOT EXISTS(
            SELECT 1 FROM deleted_users WHERE
            username = active_projects.username LIMIT 1)]] ..
            db.interpolate_query(course_name_filter())

        -- query can hold a paginator or an SQL query
        local paginator = Projects:paginated(
                 query ..
                    (self.params.data.search_term and (db.interpolate_query(
                        ' AND (projectname ILIKE ? OR notes ILIKE ?)',
                        '%' .. self.params.data.search_term .. '%',
                        '%' .. self.params.data.search_term .. '%')
                    ) or '') ..
                    ' ORDER BY ' ..
                        (self.params.data.order or 'firstpublished DESC'),
                {
                    per_page = self.params.data.per_page or 15,
                    fields = self.params.data.fields or '*'
                }
            )
        if not self.params.data.ignore_page_count then
            self.params.data.num_pages = paginator:num_pages()
        end
        self.params.data.items =
            paginator:get_page(self.params.data.page_number)
        disk:process_thumbnails(self.params.data.items)
        self.data = self.params.data
    end,
    change_page = function (self)
        if self.params.offset == 'first' then
            self.params.data.page_number = 1
        elseif self.params.offset == 'last' then
            self.params.data.page_number = self.params.data.num_pages
        else
            self.params.data.page_number = 
                math.min(
                    math.max(
                        1,
                        self.params.data.page_number + self.params.offset),
                    self.params.data.num_pages)
        end
        self.data = self.params.data
        ProjectController.fetch(self)
    end,
}
