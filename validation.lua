-- Validation and errors
-- =====================
--
-- written by Bernat Romagosa
--
-- Copyright (C) 2017 by Bernat Romagosa
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

local yield_error = package.loaded.yield_error
local Users = package.loaded.Users
local Projects = package.loaded.Projects

err = {
    not_logged_in = 'You are not logged in',
    auth = 'You do not have permission to perform this action',
    nonexistent_user = 'No user with this username exists',
    nonexistent_project = 'This project does not exist',
    not_public_project = 'This project is not public'
}

assert_all = function (assertions, self)
    for k, assertion in pairs(assertions) do
        _G['assert_' .. assertion](self)
    end
end

assert_logged_in = function (self, message)
    if not self.params.username then
        yield_error(message or err.not_logged_in)
    end
end

assert_admin = function (self, message)
    local user = Users:find(self.session.username)
    if not (user and user.isadmin) then
        yield_error(message or err.auth)
    end
end

assert_users_match = function (self, message)
    if (self.session.username ~= self.params.username) then
        -- Someone is trying to impersonate someone else
        yield_error(message or err.auth)
    end
end

assert_user_exists = function (self, message)
    if not Users:find(self.session.username) then
        yield_error(message or err.nonexistent_user)
    end
end

assert_project_exists = function (self, message)
    if not (Projects:find(self.params.username, self.params.projectname)) then
        yield_error(message or err.nonexistent_project)
    end
end

