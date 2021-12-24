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
local CollectionMemberships = package.loaded.CollectionMemberships
local Users = package.loaded.Users
local db = package.loaded.db
local disk = package.loaded.disk
local assert_error = package.loaded.app_helpers.assert_error

CollectionController = {
    run_query = function (self, query)
       local paginator = Collections:paginated(
            query ..
                (self.params.data.search_term and (db.interpolate_query(
                    ' AND (name ILIKE ? OR description ILIKE ?)',
                    '%' .. self.params.data.search_term .. '%',
                    '%' .. self.params.data.search_term .. '%')
                ) or '') ..
            ' ORDER BY ' .. (self.params.data.order or 'published_at DESC'),
            {
                per_page = self.params.data.per_page or 15,
                fields = self.params.data.fields or
                    [[collections.id, creator_id, collections.created_at,
                    published, collections.published_at, shared,
                    collections.shared_at, collections.updated_at, name,
                    description, thumbnail_id, username, editor_ids]]
            }
        )

        if not self.params.data.ignore_page_count then
            self.params.data.num_pages = paginator:num_pages()
        end

        self.items = paginator:get_page(self.params.data.page_number)
        disk:process_thumbnails(self.items, 'thumbnail_id')
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
        CollectionController[self.component.fetch_selector](self)
    end,
    fetch = function (self)
        CollectionController.run_query(
            self,
            [[JOIN active_users ON
                (active_users.id = collections.creator_id)
                WHERE published]]
        )
    end,
    changed = function (self)
        -- A component knows that this collection changed, and thus needs to be
        -- re-rendered. We just re-fetch it from the DB so that the data param
        -- is up to date when re-rendering the component
        local collection =
            Collections:find({ id = self.params.data.collection.id })
        self.params.data.collection = collection
        self.collection = collection
        self.data = self.params.data
    end,
    search = function (self)
        self.params.data.page_number = 1
        self.params.data.search_term = self.params.search_term
        CollectionController[self.component.fetch_selector](self)
    end,
    my_collections = function (self)
        self.params.data.order = 'updated_at DESC'
        CollectionController.run_query(
            self,
            db.interpolate_query(
                [[JOIN active_users ON
                    (active_users.id = collections.creator_id)
                    WHERE (creator_id = ? OR editor_ids @> ARRAY[?])]],
                self.current_user.id,
                self.current_user.id)
        )
    end,
    user_collections = function (self)
        self.params.data.order = 'updated_at DESC'
        CollectionController.run_query(
            self,
            db.interpolate_query(
                [[JOIN active_users ON
                    (active_users.id = collections.creator_id)
                    WHERE (creator_id = ? OR editor_ids @> ARRAY[?])
                    AND published]],
                self.params.data.user_id,
                self.params.data.user_id
            )
        )
    end,
    projects = function (self)
        local data = self.params.data
        local collection = Collections:find(data.user_id, data.collection_name)
        local paginator = collection:get_projects()
        paginator.per_page = data.items_per_page
        if not data.ignore_page_count then
            data.num_pages = paginator:num_pages()
        end
        self.items = paginator:get_page(data.page_number)
        disk:process_thumbnails(self.items)
        self.data = data
    end,
    containing_project = function (self)
        self.params.data.order =  'collections.created_at DESC'
        self.params.data.fields =
            [[collections.creator_id, collections.name,
            collection_memberships.project_id, collections.thumbnail_id,
            collections.shared, collections.published, users.username]]
        CollectionController.run_query(
            self,
            db.interpolate_query(
                [[INNER JOIN collection_memberships
                    ON collection_memberships.collection_id = collections.id
                INNER JOIN users
                    ON collections.creator_id = users.id
                WHERE collection_memberships.project_id = ?
                AND collections.published]],
                self.params.data.project_id
            )
        )
    end,
    new = function (self)
        assert_can_create_colletion(self)
        local collection =
            Collections:find(self.current_user.id, self.params.name)
        if not collection then
            collection = assert_error(Collections:create({
                name = self.params.name,
                creator_id = self.current_user.id
            }))
        end
        collection.username = self.current_user.username -- needed by url_for
        return collection:url_for('site')
    end,
    add_project = function (self)
        local collection = Collections:find({ id = self.params.collection.id })
        local project = Projects:find({ id = self.params.project.id })
        assert_can_add_project_to_collection(self, project, collection)

        if not collection.thumbnail_id then
            collection:update({
                thumbnail_id = project.id
            })
        end

        CollectionMemberships:create({
            collection_id = collection.id,
            project_id = project.id,
            user_id = self.current_user.id -- who added it to the collection
        })

        return project:url_for('site')
    end,
    share = function (self)
        local collection =
            Collections:find({ id = self.params.data.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            shared_at = db.format_date(),
            shared = true,
            published = false
        })
        self.params.data.collection = collection
        self.collection = collection
        self.data = self.params.data
    end,
    unshare = function (self)
        local collection =
            Collections:find({ id = self.params.data.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            shared = false,
            published = false
        })
        self.params.data.collection = collection
        self.collection = collection
        self.data = self.params.data
    end,
    publish = function (self)
        local collection =
            Collections:find({ id = self.params.data.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            published_at = collection.published_at or db.format_date(),
            shared = true,
            published = true
        })
        self.params.data.collection = collection
        self.collection = collection
        self.data = self.params.data
    end,
    unpublish = function (self)
        local collection =
            Collections:find({ id = self.params.data.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            published = false
        })
        self.params.data.collection = collection
        self.collection = collection
        self.data = self.params.data
    end,
    delete = function (self)
        local collection =
            Collections:find({ id = self.params.data.collection.id })
        local name = collection.name
        assert_can_delete(self, collection)
        db.delete('collection_memberships', { collection_id = collection.id })
        db.delete('collections', { id = collection.id })
        return jsonResponse({
            message = 'Collection <em>' .. name .. '</em> has been removed.',
            title = 'Collection removed',
            redirect = self:build_url('my_collections')
        })
    end,
}
