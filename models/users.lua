-- Users Model
-- ==========
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
local Model = require('lapis.db.Model').Model

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
--   users.updated_at,
--   users.role,
--   users.deleted,
--   users.unique_email,
--   users.last_session_at,
--   users.last_login_at
--    FROM public.users
--   WHERE (users.deleted IS NULL);
-- End active_users schema
--
local ActiveUsers = Model:extend('active_users', {
    relations = {
        {'collections', has_many = 'Collections'}
    },
    isadmin = function (self)
        return self.role == 'admin'
    end,
    ismoderator = function (self)
        return self.role == 'moderator'
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
        -- If a user is new, then their "unique email" is an unmodified email address.
        -- When emails are not unique, we will create a new unique email.
        -- Unqiue emails take the form original-address+snap-id-01234@original.domain
        unique_email = self.email
        if self:shares_email_with_others() then
            unique_email = string.gsub(self.email, '@', '+snap-id-' .. self.id .. '@')
        end
        self:update({ unique_email = unique_email })
        return unique_email
    end,
    shares_email_with_others = function (self)
        count = package.loaded.Users:count("email like '%'", self.email)
        return count > 1
    end,
    cannot_access_forum = function (self)
        return self:isbanned() or self.validated == false
    end
})

package.loaded.Users = ActiveUsers
package.loaded.DeletedUsers = Model:extend('deleted_users')

return ActiveUsers
