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
    notLoggedIn = 'you are not logged in',
    impersonate = 'you are trying to perform an action in someone else\'s name',
    auth = 'you do not have permission to perform this action',
    nonexistentUser = 'no user with this username exists',
    nonexistentProject = 'this project does not exist'
}

assert_all = function (assertions, self)
    for k, assertion in pairs(assertions) do
        _G['assert_' .. assertion](self)
    end
end

assert_logged_in = function (self)
    if not self.params.username then
        yield_error(err.notLoggedIn)
    end
end

assert_admin = function (self)
    local user = Users:find(self.session.username)
    if not (user and user.isadmin) then
        yield_error(err.auth)
    end
end

assert_users_match = function (self)
    if (self.session.username ~= self.params.username) then
        -- Someone is trying to impersonate someone else
        yield_error(err.impersonate)
    end
end

assert_user_exists = function (self)
    if not Users:find(self.session.username) then
        yield_error(err.nonexistentUser)
    end
end

assert_project_exists = function (self)
    if not (Projects:find(self.params.username, self.params.projectname)) then
        yield_error(err.nonexistentProject)
    end
end

