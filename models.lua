-- Database abstractions
-- =====================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local db = package.loaded.db
local Model = package.loaded.Model

local contains = package.loaded.helpers.contains

package.loaded.Users = Model:extend('active_users', {
    relations = {
        {'collections', has_many = 'Collections'}
    },
    isadmin = function (self)
        return self.role == 'admin'
    end,
    isbanned = function (self)
        return self.role == 'banned'
    end,
    has_one_of_roles = function (self, roles)
        for _, role in pairs(roles) do
            if self.role == role then
                return true
            end
        end
        return false
    end,
    rollbar_params = function (self)
        -- just the info necessary for error tracking
        return {id = self.id, username = self.username}
    end
})

local Users = package.loaded.Users
package.loaded.DeletedUsers = Model:extend('deleted_users')

package.loaded.Projects = Model:extend('active_projects', {
    primary_key = {'username', 'projectname'},
    constraints = {
        projectname = function (_self, name)
            if not name or string.len(name) < 1 then
                return "Project names must have at least one character."
            end
        end
    },
    relations = {
        {'collections', -- a project has many collections through collection memberships
         many = true,
         fetch = function(self)
            return Collections:select('JOIN collection_memberships cm ON cm.collection_id = collections.id JOIN projects p ON p.id = cm.project_id WHERE p.id = ?', self.id)
         end},
         {'user', has_one = 'User', key = 'username'}
    },
    user_can_view = function(self, user)
        -- Users can view their own projects, or public ("shared") projects.
        -- Users can also view projects that are private, but exist in collections they can view.
        if self.username == user.username or self.ispublic then
            return true
        else
            local collections = self:get_collections()
            for _, collection in pairs(collections) do
                if collection:user_can_view(user) then
                    return true
                end
            end
            return false
        end
    end
})

package.loaded.DeletedProjects = Model:extend('deleted_projects', {
    primary_key = {'username', 'projectname'}
})

package.loaded.Tokens = Model:extend('tokens', {
    primary_key = {'value'}
})

package.loaded.Remixes = Model:extend('remixes', {
    primary_key = {'original_project_id', 'remixed_project_id'}
})

package.loaded.Collections = Model:extend('collections', {
    primary_key = {'creator_id', 'name'},
    timestamp = true,
    relations = {
        -- creates Collection:get_creator(), written this way to only select relevant fields.
        {'creator', fetch = function (self)
            return Users:select('WHERE id = ?', self.creator_id, {fields = 'username, id'})[1]
        end},
        {'memberships', has_many = 'CollectionMemberships'},
        {'editors', many = true, fetch = function (self)
            if self.editor_ids then
                return Users:find_all(self.editor_ids)
            else
                return {}
            end
        end},
        {'viewers', many = true, fetch = function (self)
            if self.viewer_ids then
                return User:find_all(self.viewer_ids)
            else
                return {}
            end
        end},
        {'projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ WHERE id IN (
                        SELECT project_id
                        FROM collection_memberships
                        WHERE collection_id = ?
                    )]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'shared_and_published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ WHERE id IN (
                        SELECT project_id
                        FROM collection_memberships
                        WHERE collection_id = ?
                    )
                    AND (ispublished OR ispublic) ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ WHERE id IN (
                        SELECT project_id
                        FROM collection_memberships
                        WHERE collection_id = ?
                    )
                    AND ispublished ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        }
    },
    constraints = {
        name = function(self, value)
            if not value then
                return 'A name must be present'
            end
        end
    },
    count_projects = function (self)
        return package.loaded.CollectionMemberships:count('collection_id = ?',
                                                          self.id)
    end,
    user_can_view = function (self, user)
        if self.id == 0 then
            -- Reviewers, moderators and admins can view the Flagged collection
            return user:has_one_of_roles({ 'reviewer', 'moderator', 'admin' })
        else
            return self.shared or self.published or self.creator_id == user.id or
                contains(self.editor_ids, user.id) or contains(self.reviewer_ids, user.id)
        end
    end,
    user_can_edit = function (self, user)
        return self.creator_id == user.id or contains(self.editor_ids, user.id) or user:isadmin()
    end,
    user_can_add_project = function (self, project, user)
        -- Admins can add any project to any collection.
        -- Anyone can add projects to the "Flagged" collection, with id == 0
        if user:isadmin() or self.id == 0 then return true end

        -- Users can add their own projects and published projects
        -- to collections they can edit.
        -- Users cannot add others' shared projects to a collection.
        return self:user_can_edit(user) and
            (project.username == self.current_user.username or project.ispublished)
    end
})

local Collection = package.loaded.Collections

package.loaded.CollectionMemberships = Model:extend(
    'collection_memberships', {
        primary_key = {'collection_id', 'project_id'},
        timestamp = true
    }
)

package.loaded.BannedIPs = Model:extend(
    'banned_ips', {
        primary_key = 'ip',
        timestamp = true
    }
)
