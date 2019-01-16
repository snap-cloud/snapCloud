-- Users module
-- ============
--
-- Written by Bernat Romagosa
--
-- Copyright (C) 2019 by Bernat Romagosa
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

local app = package.loaded.app
local db = package.loaded.db
local Users = package.loaded.Users

-- User roles:
-- standard:  Can view published and shared projects, can do anything to own projects,
--            can see basic user profile data. Can delete oneself.
-- reviewer:  Same as standard, plus: Can unpublish projects.
-- moderator: Same as reviewer, plus: Can delete published and shared projects.
--            Can block users. Can delete users. Can verify users.
-- admin:     Can do everything.
-- banned:    Same as a standard user, but can't modify or add anything.

-- ↓↓ MOVE TO models.lua ↓↓
function is_project (object)
    return object.__class:singular_name() == 'project'
end

function is_user (object)
    return object.__class:singular_name() == 'user'
end

function is_collection (object)
    return object.__class:singular_name() == 'collection'
end
-- ↑↑ MOVE TO models.lua ↑↑

Users.__base:is_admin_or_owns = function (object)
    return object.username == self.username or self.role == 'admin'
end

-- define all functions for is_admin, is_banned, etc.
for _, role in pairs({'standard', 'reviewer', 'moderator', 'admin', 'banned'}) do
    Users.__base['is_' .. role] = function ()
        return self.role == role
    end
end

Users.__base:can_view = function (object)
    if is_project(object) then
        return object.ispublished or
                object.ispublic or
                self:is_admin_or_owns(object)
    else if is_collection(object) then
        -- TODO
    end
end

Users.__base:can_delete = function (object)
    if is_project(object) or is_user(object) then
        return self:is_admin_or_owns(object) or
                (self.role == 'moderator' and 
                    (object.ispublic or object.ispublished))
    else if is_collection(object) then
        -- TODO
    end
end

Users.__base:can_modify = function (object, param)
    -- param is optional
    return self['can_modify_' .. object.__class:singular_name()](object, param)
end

Users.__base:can_modify_project = function (param)
    return self:is_admin_or_owns(object)
end

