-- Community site controller
-- =========================
--
-- Actions and database queries for all community site routes.
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

component.queries = {
    explore_users = {
        fetch =
            function (session, data)
                return 'WHERE true'
            end,
        order = 'username'

    },
    collection_projects = {
        fetch = function (session, data)
            local collection =
                Collections:find(data.user_id, data.collection_name)
            local paginator = collection:get_projects()
            paginator.per_page = data.per_page or 5
            return paginator
        end
    },
    flags = {
        fetch = function (session, data)
            return [[INNER JOIN flagged_projects ON
                    active_projects.id = flagged_projects.project_id
                WHERE active_projects.ispublic
                GROUP BY active_projects.projectname,
                    active_projects.username,
                    active_projects.id]]
        end,
        order = 'flag_count DESC',
        fields = [[active_projects.id AS id,
            active_projects.projectname AS projectname,
            active_projects.username AS username,
            count(*) AS flag_count]]
    }
}

component.actions['grid'] = {
    first = function (session, data, _)
        data.page_number = 1
        component.actions['grid'].update_items(session, data)
    end,
    last = function (session, data, _)
        data.page_number = data.num_pages
        component.actions['grid'].update_items(session, data)
    end,
    next = function (session, data, params)
        data.page_number =
            math.min(data.num_pages, data.page_number + params[1])
        component.actions['grid'].update_items(session, data)
    end,
    previous = function (session, data, params)
        data.page_number = math.max(1, data.page_number - params[1])
        component.actions['grid'].update_items(session, data)
    end,
    search = function (session, data, params)
        data.search_term = params[1]
        data.page_number = 1
        component.actions['grid'].update_items(session, data)
    end,
    update_items = function (session, data, _)
        component.actions['grid'][
            'update_' .. data.item_type .. 's'](session, data)
    end,
    update_projects = function (session, data, _)
        local query = component.queries[data.query].fetch(session, data)
        -- query can hold a paginator or an SQL query
        local paginator = query.per_page and query or
            Projects:paginated(
                 query ..
                    (data.search_term and (db.interpolate_query(
                        ' AND (projectname ILIKE ? OR notes ILIKE ?)',
                        '%' .. data.search_term .. '%',
                        '%' .. data.search_term .. '%')
                    ) or '') ..
                ' ORDER BY ' .. component.queries[data.query].order,
                {
                    per_page = data.per_page or 15,
                    fields = component.queries[data.query].fields or '*'
                }
            )
        if not data.ignore_page_count then
            data.num_pages = paginator:num_pages()
        end
        data.items = paginator:get_page(data.page_number)
        disk:process_thumbnails(data.items)
    end,
    update_collections = function (session, data, _)
        local query = component.queries[data.query].fetch(session, data)
        local paginator = Collections:paginated(
            query ..
                (data.search_term and (db.interpolate_query(
                    ' AND (name ILIKE ? OR description ILIKE ?)',
                    '%' .. data.search_term .. '%',
                    '%' .. data.search_term .. '%')
                ) or '') ..
            ' ORDER BY ' .. component.queries[data.query].order,
            {
                per_page = data.per_page or 15,
                fields = component.queries[data.query.fields] or
                    [[collections.id, creator_id, collections.created_at,
                    published, collections.published_at, shared,
                    collections.shared_at, collections.updated_at, name,
                    description, thumbnail_id, username, editor_ids]]
            }
        )

        data.num_pages = paginator:num_pages()
        data.items = paginator:get_page(data.page_number)
        disk:process_thumbnails(data.items, 'thumbnail_id')
    end,
    update_users = function (session, data, _)
        local query = component.queries[data.query].fetch(session, data)
        local paginator = Users:paginated(
            query ..
                (data.search_term and (db.interpolate_query(
                    ' AND username ILIKE ? OR email ILIKE ?',
                    '%' .. data.search_term .. '%',
                    '%' .. data.search_term .. '%')
                ) or '') ..
            ' ORDER BY ' .. component.queries[data.query].order,
            {
                per_page = data.per_page or 15,
                fields = component.queries[data.query.fields] or '*'
            }
        )

        data.num_pages = paginator:num_pages()
        data.items = paginator:get_page(data.page_number)
    end,
    update_profiles = function (session, data, _)
        local query = component.queries[data.query].fetch(session, data)
        local paginator = Users:paginated(
            query ..
                (data.search_term and (db.interpolate_query(
                    ' AND username ILIKE ? OR email ILIKE ?',
                    '%' .. data.search_term .. '%',
                    '%' .. data.search_term .. '%')
                ) or '') ..
            ' ORDER BY ' .. component.queries[data.query].order,
            {
                per_page = data.per_page or 15,
                fields = component.queries[data.query.fields] or '*'
            }
        )

        data.num_pages = paginator:num_pages()
        data.items = paginator:get_page(data.page_number)
    end
}


