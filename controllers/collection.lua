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
local yield_error = package.loaded.yield_error

CollectionController = {
    run_query = function (self, query)
        if not self.params.page_number then self.params.page_number = 1 end
        local paginator = Collections:paginated(
            query ..
                (self.params.search_term and (db.interpolate_query(
                    ' AND (name ILIKE ? OR description ILIKE ?)',
                    '%' .. self.params.search_term .. '%',
                    '%' .. self.params.search_term .. '%')
                ) or '') ..
            ' ORDER BY ' .. (self.params.order or 'published_at DESC'),
            {
                per_page = self.params.per_page or 15,
                fields = self.params.fields or
                    [[collections.id, creator_id, collections.created_at,
                    published, collections.published_at, shared,
                    collections.shared_at, collections.updated_at, name,
                    description, thumbnail_id, username, editor_ids]]
            }
        )

        if not self.params.ignore_page_count then
            self.num_pages = paginator:num_pages()
        end

        local items = paginator:get_page(self.params.page_number)
        disk:process_thumbnails(items, 'thumbnail_id')
        return items
    end,
    fetch = function (self)
        return CollectionController.run_query(
            self,
            [[JOIN active_users ON
                (active_users.id = collections.creator_id)
                WHERE published]]
        )
    end,
    my_collections = function (self)
        self.params.order = 'updated_at DESC'
        return CollectionController.run_query(
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
        self.params.order = 'updated_at DESC'
        return CollectionController.run_query(
            self,
            db.interpolate_query(
                [[JOIN active_users ON
                    (active_users.id = collections.creator_id)
                    WHERE (creator_id = ? OR editor_ids @> ARRAY[?])
                    AND published]],
                self.params.user_id,
                self.params.user_id
            )
        )
    end,
    projects = function (self)
        local collection = Collections:find(user_id, collection_name)
        local paginator = collection:get_projects()
        paginator.per_page = items_per_page
        if not ignore_page_count then
            num_pages = paginator:num_pages()
        end
        local items = paginator:get_page(page_number)
        disk:process_thumbnails(self.items)
        return items
    end,
    containing_project = function (self)
        self.params.order =  'collections.created_at DESC'
        self.params.fields =
            [[collections.creator_id, collections.name,
            collection_memberships.project_id, collections.thumbnail_id,
            collections.shared, collections.published, users.username]]
        return CollectionController.run_query(
            self,
            db.interpolate_query(
                [[INNER JOIN collection_memberships
                    ON collection_memberships.collection_id = collections.id
                INNER JOIN users
                    ON collections.creator_id = users.id
                WHERE collection_memberships.project_id = ?
                AND collections.published]],
                self.params.project_id
            )
        )
    end,
    new = function (self)
        assert_can_create_collection(self)
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
        assert_project_not_in_collection(self, project, collection)

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
    remove_project = function (self)
        local collection =
            Collections:find({ id = self.params.collection_id })

        -- For now, only creators can add projects to collections. Should
        -- editors also be able to?
        if collection.creator_id ~= self.current_user.id then
            assert_min_role(self, 'moderator')
        end

        db.delete(
            'collection_memberships',
            {
                collection_id = collection.id,
                project_id = self.params.project.id
            })
    end,
    set_thumbnail = function (self)
        local collection =
            Collections:find({ id = self.params.collection_id })

        if collection.creator_id ~= self.current_user.id then
            assert_min_role(self, 'moderator')
        end

        collection:update({ thumbnail_id = self.params.project.id })
        collection.thumbnail =
            package.loaded.disk:retrieve_thumbnail(collection.thumbnail_id)
    end,
    share = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            shared_at = db.format_date(),
            shared = true,
            published = false
        })
    end,
    unshare = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            shared = false,
            published = false
        })
    end,
    publish = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            published_at = collection.published_at or db.format_date(),
            shared = true,
            published = true
        })
    end,
    unpublish = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        assert_can_share(self, collection)
        collection:update({
            updated_at = db.format_date(),
            published = false
        })
    end,
    delete = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
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
    make_ffa = function (self)
        assert_min_role(self, 'moderator')
        local collection =
            Collections:find({ id = self.params.collection.id })
        collection:update({ free_for_all = true })
        if collection.editor_ids then
            collection.editors = Users:find_all(
                collection.editor_ids,
                { fields = 'username, id' }
            )
        end
        collection.creator = Users:find({ id = collection.creator_id })
        return jsonResponse({
            message = 'Collection <em>' .. collection.name ..
                '</em> is now free for all.',
            title = 'Free for all'
        })
    end,
    unmake_ffa = function (self)
        assert_min_role(self, 'moderator')
        local collection =
            Collections:find({ id = self.params.collection.id })
        collection:update({ free_for_all = false })
        if collection.editor_ids then
            collection.editors = Users:find_all(
            collection.editor_ids,
            { fields = 'username, id' })
        end
        collection.creator = Users:find({ id = collection.creator_id })
        return jsonResponse({
            message = 'Collection <em>' .. collection.name ..
                '</em> is no longer free for all.',
            title = 'Free for all'
        })
    end,
    unenroll = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        if is_editor(self, collection) then
            collection:update({
                editor_ids =
                    db.raw(db.interpolate_query(
                        'array_remove(editor_ids, ?)',
                        self.current_user.id))
            })
        end
        return jsonResponse({
            message = 'You are no longer an editor of this collection.',
            title = 'Unenrolled',
            redirect = self:build_url('my_collections')
        })
    end,
    add_editor = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        if collection.creator_id ~= self.current_user.id then
            assert_admin(self)
        end

        local editor = Users:find(
            { username = self.params.editor.username })
        if not editor then yield_error(err.nonexistent_user) end

        collection:update({
            editor_ids =
                db.raw(db.interpolate_query(
                    'array_append(editor_ids, ?)',
                    editor.id))
        })
    end,
    remove_editor = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        if collection.creator_id == self.current_user.id or
                is_editor(self, collection) or
                current_user:isadmin() then
            collection:update({
                editor_ids =
                    db.raw(db.interpolate_query(
                        'array_remove(editor_ids, ?)',
                        self.params.editor.id))
            }) 
        else
            yield_error(err.auth)
        end
    end,
    rename = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        if collection.creator_id ~= self.current_user.id then
            assert_admin(self)
        end
        -- assign the creator so we can redirect to the new collection URL
        collection.creator = Users:find({ id = collection.creator_id })
        if not (collection:update({ name = self.params.new_name })) then
            return errorResponse('Collection could not be renamed')
        else
            return collection:url_for('site')
        end
    end,
    set_description = function (self)
        local collection =
            Collections:find({ id = self.params.collection.id })
        if collection.creator_id ~= self.current_user.id then
            assert_admin(self)
        end
        if not 
            (collection:update({ description = self.params.new_description }))
                then
            return errorResponse('Collection description could not be updated')
        end
    end
}
