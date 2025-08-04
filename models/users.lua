-- Snap!Cloud User Model
-- =====================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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

local Model = package.loaded.Model
local util = require('lapis.util')
local escape = util.escape

-- Generated schema dump: (do not edit)
--
-- CREATE VIEW active_users AS
--  SELECT users.id,
--   users.created,
--   users.username,
--   users.email,
--   users.salt,
--   users.password,
--   users.about,
--   users.location,
--   users.verified,
--   users.role,
--   users.deleted,
--   users.unique_email,
--   users.bad_flags,
--   users.is_teacher,
--   users.creator_id
--    FROM public.users
--   WHERE (users.deleted IS NULL);
--
local ActiveUsers = Model:extend('active_users', {
    type = 'user',
    constraints = {
        -- TODO: add conatrains for usernames, etc.
        -- username = function(self, value) end,
        email = function (self, value)
            if not value or value == '' then
                return 'email must be present'
            end
            value = util.trim(tostring(value))
            if #value < 6 then
                return 'email must be at least 6 characters'
            elseif not string.find(value, "@") then
                return 'email must contain an "@"'
            end
        end
    },
    relations = {
        {'collections', has_many = 'Collections'},
        {'editable_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE (collections.creator_id = ? OR editor_ids @> array[?]) OR
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
                    [[WHERE collections.creator_id = ? AND collections.free_for_all]],
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'public_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE collections.creator_id = ? AND published ]],
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
    is_student = function (self)
        return self.role == 'student'
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
        local unique_email = self.email
        if self:shares_email_with_others() then
            unique_email =
                string.gsub(self.email, '@', '+snap-id-' .. self.id .. '@')
        end
        self:update({ unique_email = unique_email })
        return unique_email
    end,
    shares_email_with_others = function (self)
        local count = package.loaded.AllUsers:count("unique_email ilike ?", self.email)
        return count > 0
    end,
    cannot_access_forum = function (self)
        return self:is_student() or self:isbanned() or self.validated == false
    end
})


-- Note: Due to client-side pre-hashing, password length isn't useful...
ActiveUsers.validations = {
    { 'username', exists = true, min_length = 4, max_length = 200 },
    { 'password', exists = true, min_length = 6 },
    { 'email', exists = true, min_length = 5 }
}

ActiveUsers.roles = {
    admin = 5,
    moderator = 4,
    reviewer = 3,
    standard = 2,
    student = 1,
    banned = 0
}

package.loaded.DeletedUsers = Model:extend('deleted_users')

-- Used for queries across the entire users table.
package.loaded.AllUsers = Model:extend('users')

return ActiveUsers
