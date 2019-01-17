-- Validation and errors
-- =====================
--
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local db = package.loaded.db
local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Tokens = package.loaded.Tokens
local url = require 'socket.url'

require 'responses'
require 'email'

err = {
    not_logged_in = {msg = 'You are not logged in', status = 401},
    auth = {msg = 'You do not have permission to perform this action', status = 403},
    nonexistent_user = {msg = 'No user with this username exists', status = 404},
    nonexistent_project = {msg = 'This project does not exist', status = 404},
    not_public_project = {msg = 'This project is not public', status = 403},
    expired_token = {msg = 'This token has expired', status = 401},
    invalid_token = {msg = 'This token is either invalid or has expired', status = 401},
    nonvalidated_user = {msg = 'This user has not been validated within the first 3 days after its creation.\nPlease use the cloud menu to ask for a new validation link.', status = 401},
    invalid_role = {msg = 'This user role is not valid', status = 401},
}

assert_all = function (assertions, self)
    for _, assertion in pairs(assertions) do
        if (type(assertion) == 'string') then
            _G['assert_' .. assertion](self)
        else
            assertion(self)
        end
    end
end

-- User permissions and roles

assert_logged_in = function (self, message)
    if not self.session.username then
        yield_error(message or err.not_logged_in)
    end
end

-- User roles:
-- standard:  Can view published and shared projects, can do anything to own projects,
--            can see basic user profile data. Can delete oneself.
-- reviewer:  Same as standard, plus: Can unpublish projects.
-- moderator: Same as reviewer, plus: Can delete published and shared projects.
--            Can block users. Can delete users. Can verify users.
-- admin:     Can do everything.
-- banned:    Same as a standard user, but can't modify or add anything.

function Users.__base:isadmin ()
    return self.role == 'admin'
end

function Users.__base:has_one_of_roles (roles)
    for _, role in pairs(roles) do
        if self.role == role then
            return true
        end
    end
    return false
end

assert_role = function (self, role, message)
    if not (self.current_user and self.current_user.role == role) then
        yield_error(message or err.auth)
    end
end

assert_has_one_of_roles = function (self, roles)
    if not self.current_user:has_one_of_roles(roles) then
        yield_error(err.auth)
    end
end

assert_admin = function (self, message)
    assert_role(self, 'admin', message)
end

assert_can_set_role = function (self, role)
    -- admins can do anything
    if self.current_user:isadmin() then return true end

    -- nobody but admins can revoke roles from admins
    if self.queried_user:isadmin() then yield_error(err.auth) end

    -- now for the rest of the cases
    if role == 'banned' then
        -- moderators can ban anyone but admins (already taken care of) or moderators
        if self.queried_user.role ~= 'moderator' then
            assert_role(self, 'moderator')
        else
            yield_error(err.auth)
        end
    else if role == 'admin' then
        -- only admins can grant admin roles to others
        yield_error(err.auth)
    else if role == 'moderator' then
        -- only admins and moderators can grant moderator roles to others.
        -- moderators can't turn admins into moderators as per second check at the top of this function.
        assert_role(self, 'moderator')
    else if role == 'reviewer' then
        -- admins (already taken care of), moderators, and reviewers can grant reviewer roles to others.
        -- nobody can turn admins into reviewers as per second check at the top of this function, but
        -- we need to make sure that reviewers can't downgrade moderators.
        if self.queried_user.role == 'moderator' then
            assert_role(self, 'moderator')
        else
            assert_has_one_of_roles(self, { 'moderator', 'reviewer' })
        end
    else if role == 'standard' then
        -- admins can downgrade moderators or reviewers to standard users (taken care of)
        -- moderators can downgrade reviewers to standard users
        if self.queried_user.role = 'reviewer' then
            assert_role(self, 'moderator')
        end
    else
        yield_error(err.invalid_role)
    end
end

users_match = function (self)
    return (self.session.username == self.params.username)
end

assert_users_match = function (self, message)
    if (not users_match(self)) then
        -- Someone is trying to impersonate someone else
        yield_error(message or err.auth)
    end
end

assert_user_exists = function (self, message)
    if not self.queried_user then
        yield_error(message or err.nonexistent_user)
    end
    return self.queried_user
end

-- Projects

assert_project_exists = function (self, message)
    if not (Projects:find(self.params.username, self.params.projectname)) then
        yield_error(message or err.nonexistent_project)
    end
end

-- Tokens

check_token = function (token_value, purpose, on_success)
    local token = Tokens:find(token_value)
    if token then
        local query = db.select("date_part('day', now() - ?::timestamp)", token.created)[1]
        if query.date_part < 4 and token.purpose == purpose then
            -- TODO: use self.queried_user and assert matches token.username
            local user = Users:find(token.username)
            token:delete()
            return on_success(user)
        elseif token.purpose ~= purpose then
            -- We simply ignore tokens with different purposes
            return htmlPage('Invalid token', '<p>' .. err.invalid_token.msg .. '</p>')
        else
            -- We delete expired tokens with 'verify_user' purpose
            token:delete()
            return htmlPage('Expired token', '<p>' .. err.expired_token.msg .. '</p>')
        end
    else
        -- This token does not exist anymore, or never existed in the first place
        return htmlPage('Invalid token', '<p>' .. err.invalid_token.msg .. '</p>')
    end
end

--- Creates a token and sends an email
-- @param self: request object
-- @param purpose string: token purpose and route name
-- @param username string
-- @param email string
create_token = function (self, purpose, username, email)
    local token_value = secure_token()
    Tokens:create({
        username = username,
        created = db.format_date(),
        value = token_value,
        purpose = purpose
    })
    send_mail(
        email,
        mail_subjects[purpose] .. username,
        mail_bodies[purpose],
        self:build_url(self:url_for(
            purpose,
            {
                username = url.build_path({username}),
                token = url.build_path({token_value}),
            }
        ))
    )
end
