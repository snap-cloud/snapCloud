-- Collection controller
-- =====================
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

CollectionController = {
    fetch = function (self)
        local data = self.params.data
        local collection = Collections:find(data.user_id, data.collection_name)
        local paginator = collection:get_projects()
        if not data.ignore_page_count then
            data.num_pages = paginator:num_pages()
        end
        paginator.per_page = data.items_per_page
        data.items = paginator:get_page(data.page_number)
        disk:process_thumbnails(data.items)
        self.data = data
    end,
    change_page = function (self)
        local data = self.params.data
        if self.params.amount == 'first' then
            data.page_number = 1
        elseif self.params.amount == 'last' then
            data.page_number = data.num_pages
        else
            data.page_number = data.page_number + self.params.amount
        end
        self.data = data
        CollectionController.fetch(self)
    end
}
