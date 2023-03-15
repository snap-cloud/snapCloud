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

local escape = package.loaded.util.escape
local disk = package.loaded.disk

package.loaded.Users = Model:extend('active_users', {
    type = 'user',
    relations = {
        {'collections', has_many = 'Collections'},
        {'editable_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE (creator_id = ? OR editor_ids @> array[?]) OR
                        collections.free_for_all]],
                    self.id,
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'ffa_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE creator_id = ? AND collections.free_for_all]],
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'public_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE creator_id = ? AND published ]],
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'project_count',
            fetch = function (self)
                return package.loaded.Projects:select(
                    'WHERE username = ?',
                    self.username,
                    { fields = 'count(*) as count' }
                )[1].count
            end
        },
    },
    follows = function (self, a_user)
        return package.loaded.Followers:find({
            follower_id = self.id,
            followed_id = a_user.id
        }) ~= nil
    end,
    isadmin = function (self)
        return self.role == 'admin'
    end,
    ismoderator = function (self)
        return self.role == 'moderator'
    end,
    isbanned = function (self)
        return self.role == 'banned'
    end,
    is_teacher = function (self)
        -- This is likely to get more complex in the future.
        return self.is_teacher
    end,
    has_min_role = function (self, expected_role)
        return package.loaded.Users.roles[self.role] >=
            package.loaded.Users.roles[expected_role]
    end,
    has_one_of_roles = function (self, roles)
        for _, role in pairs(roles) do
            if self.role == role then
                return true
            end
        end
        return false
    end,
    url_for = function (self, purpose)
        local urls = {
            site = '/user?username=' .. escape(self.username)
        }
        return urls[purpose]
    end,
    logging_params = function (self)
        -- Identifying info, excluding email (PII)
        return { id = self.id, username = self.username }
    end,
    discourse_email = function (self)
        if self.unique_email ~= nil and self.unique_email ~= '' then
            return self.unique_email
        end
        return self:ensure_unique_email()
    end,
    ensure_unique_email = function (self)
        -- If a user is new, then their "unique email" is an unmodified email
        -- address.
        -- When emails are not unique, we will create a new unique email.
        -- Unique emails take the form:
        --                      original-address+snap-id-01234@original.domain
        unique_email = self.email
        if self:shares_email_with_others() then
            unique_email =
                string.gsub(self.email, '@', '+snap-id-' .. self.id .. '@')
        end
        self:update({ unique_email = unique_email })
        return unique_email
    end,
    shares_email_with_others = function (self)
        count = package.loaded.Users:count("unique_email ilike ?", self.email)
        return count > 0
    end,
    cannot_access_forum = function (self)
        return self:isbanned() or self.validated == false
    end
})

package.loaded.Users.validations = {
    { 'username', exists = true, min_length = 4, max_length = 200 },
    { 'password', exists = true, min_length = 6 },
    { 'email', exists = true, min_length = 5 }
}

package.loaded.Users.roles = {
    admin = 4,
    moderator = 3,
    reviewer = 2,
    standard = 1,
    banned = 0
}

package.loaded.DeletedUsers = Model:extend('deleted_users')

-- Used for querires across the entire users table.
package.loaded.AllUsers = Model:extend('users')

package.loaded.Projects = Model:extend('active_projects', {
    type = 'project',
    primary_key = {'username', 'projectname'},
    constraints = {
        projectname = function (_self, name)
            if not name or string.len(name) < 1 then
                return "Project names must have at least one character."
            end
        end
    },
    url_for = function (self, purpose, dev_version)
        local base = 'https://snap.berkeley.edu/' ..
            (dev_version and 'snapsource/dev/' or '') ..
            'snap.html'
        local urls = {
            viewer = base ..
                '#present:Username=' .. escape(self.username) ..
                '&ProjectName=' .. escape(self.projectname) ..
                '&embedMode&noExitWarning&noRun',
            open = base ..
                '#present:Username=' .. escape(self.username) ..
                '&ProjectName=' .. escape(self.projectname) ..
                '&editMode&noRun',
            download = '/project/' .. escape(self.id),
            site = '/project?username=' .. escape(self.username) ..
                '&projectname=' .. escape(self.projectname),
            author = '/user?username=' .. escape(self.username),
            embed = 'https://snap.berkeley.edu/embed?projectname=' ..
                escape(self.projectname) .. '&username=' ..
                escape(self.username)
        }
        return urls[purpose]
    end,
    relations = {
        {'flags',
            fetch = function (self)
                return package.loaded.FlaggedProjects:select(
                    'JOIN active_users ON active_users.id = flagger_id '..
                    'WHERE project_id = ? ' ..
                    'GROUP BY reason, username, created_at, notes',
                    self.id,
                    { fields = 'username, created_at, reason, notes' }
                )
            end
        },
        {'public_remixes',
            fetch = function (self)
                local items = package.loaded.Projects:select(
                   [[JOIN remixes
                        ON active_projects.id = remixes.remixed_project_id
                    WHERE remixes.original_project_id = ?
                    AND ispublic]],
                    self.id
                )
                disk:process_thumbnails(items)
                return items
            end
        },
        {'public_collections',
            fetch = function (self)
                local items = package.loaded.Collections:select(
                    [[INNER JOIN collection_memberships
                        ON collection_memberships.collection_id = collections.id
                    INNER JOIN users
                        ON collections.creator_id = users.id
                    WHERE collection_memberships.project_id = ?
                    AND collections.published]],
                    self.id
                )
                disk:process_thumbnails(items, 'thumbnail_id')
                return items
            end
        }
    }
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
    type = 'collection',
    primary_key = {'creator_id', 'name'},
    timestamp = true,
    url_for = function (self, purpose)
        if not self.username then
            if not self.creator then
                self.creator = package.loaded.Users:find(self.creator_id)
            end
            self.username = self.creator.username
        end
        local urls = {
            site = '/collection?username=' .. escape(self.username) ..
                '&collection=' .. escape(self.name),
            author = '/user?username=' .. escape(self.username)
        }
        return urls[purpose]
    end,
    relations = {
        -- creates Collection:get_creator()
        {'creator', belongs_to = 'Users', key = 'creator_id'},
        {'memberships', has_many = 'CollectionMemberships'},
        {'projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                        AS memberships
                        ON active_projects.id = memberships.project_id
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'shared_and_published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                        AS memberships
                        ON active_projects.id = memberships.project_id
                        WHERE (ispublished OR ispublic)
                        ORDER BY memberships.created_at DESC ]],
                    self.id)
                return package.loaded.Projects:paginated(query)
            end
        },
        {'published_projects',
            fetch = function (self)
                local query = db.interpolate_query(
                    [[ INNER JOIN (
                            SELECT project_id, created_at
                            FROM collection_memberships
                            WHERE collection_id = ?)
                        AS memberships
                        ON active_projects.id = memberships.project_id
                        WHERE ispublished
                        ORDER BY memberships.created_at DESC ]],
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
    end
})

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

package.loaded.FlaggedProjects = Model:extend(
    'flagged_projects', {
        primary_key = 'id',
        timestamp = true
    }
)

package.loaded.FeaturedCollections = Model:extend(
    'featured_collections', {
        primary_key = {'collection_id', 'page_path'},
        timestamp = true
    }
)

package.loaded.Followers = Model:extend(
    'followers', {
        primary_key = {'follower_id', 'followed_id'},
        timestamp = true
    }
)
