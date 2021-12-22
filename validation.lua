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
local Collections = package.loaded.Collections
local CollectionMemberships = package.loaded.CollectionMemberships
local Users = package.loaded.Users
local Projects = package.loaded.Projects
local Tokens = package.loaded.Tokens
local url = require 'socket.url'
local exceptions = require 'lib.exceptions'
local socket = require('socket')
local http = require('lapis.nginx.http')

require 'responses'
require 'email'

err = {
    not_logged_in = { msg = 'You are not logged in', status = 401 },
    auth = {
        msg = 'You do not have permission to perform this action',
        status = 403 },
    wrong_password = {
        msg = 'The provided password is wrong',
        status = 403 },
    nonexistent_user =
        { msg = 'No user with this username exists', status = 404 },
    nonexistent_email =
        { msg = 'No users are associated to this email account', status = 404 },
    nonexistent_project =
        { msg = 'This project does not exist or is private', status = 404 },
    nonexistent_collection =
        { msg = 'This collection does not exist', status = 404 },
    expired_token = { msg = 'This token has expired', status = 401 },
    invalid_token =
        { msg = 'This token is either invalid or has expired', status = 401 },
    nonvalidated_user =
        { msg = 'Your user has not been validated.', status = 403 },
    nonvalidated_user_plaintext = {
        msg = 'This user has not been validated within the first 3 days ' ..
                'after its creation.\nPlease use the cloud menu to ask for ' ..
                'a new validation link.',
        status = 401 },
    nonvalidated_user_html = {
        msg = '<p>This user has not been validated within the first 3 days ' ..
            'after its creation.</p>' ..
            '<p>Please <a href="/run">open the Snap<em>!</em> editor</a> and' ..
            ' then use the cloud menu to ask for a new validation link:</p>' ..
            '<p><img src="/static/cloud_menu.png"></img></p>',
        status = 401 },
    invalid_role = { msg = 'This user role is not valid', status = 401 },
    banned = { msg = 'Your user has been banned', status = 403 },
    user_too_new = {
        msg = 'Your user has not had enough activity in this community' ..
            ' and it cannot yet create collections.',
        status = 403 },
    update_project_fail =
        { msg = 'Project could not be updated', status = 500 },
    unparseable_xml =
        { msg = 'Project file could not be parsed', status = 500 },
    file_not_found = { msg = 'Project file not found', status = 404 },
    mail_body_empty = { msg = 'Missing email body contents', status = 400 },
    project_already_in_collection =
        { msg = 'This project is already in that collection', status = 409 },
    collection_contains_unshared_projects = {
        msg = 'This collection cannot be shared' ..
            ' as it contains private projects',
        status = 409 },
    collection_contains_unpublished_projects = {
        msg = 'This collection cannot be published' ..
            ' as it contains unpublished projects',
        status = 409 },
    unpublished_project_in_ffa_collection = {
        msg = 'You need to first publish your project before you can add it' ..
            ' to this collection',
        status = 409 },
    too_many_password_resets = {
        msg = 'A password reset email has already been sent to this user ' ..
            'recently.<br/>Please check your spam folder, or wait a few ' ..
            'minutes and try again.',
        status = 429 },
    project_already_flagged =
        { msg = 'You have already flagged this project.', status = 409 },
    project_never_flagged =
        { msg = 'This project was not flagged by you.', status = 404 },
    method_not_allowed =
        {
            msg = 'This API endpoint does not respond to this HTTP method.',
            status = 405
        },
    too_fast =
        { msg = 'Too many requests. Slow down.', status = 429 },
    too_soon =
        { msg = 'Please wait a few seconds and try again.', status = 429 },
    session_reused =
        { msg = 'Please use the Snap! site, not scripts.', status = 409 },
    tor_not_allowed =
        { msg = 'Sorry. We cannot let you use Tor for that.', status = 403 },
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
-- standard:  Can view published and shared projects, can do anything to own
--            projects, can see basic user profile data. Can delete oneself.
-- reviewer:  Same as standard, plus: Can unpublish projects.
-- moderator: Same as reviewer, plus: Can delete published and shared projects.
--            Can block users. Can delete users. Can verify users.
-- admin:     Can do everything.
-- banned:    Same as a standard user, but can't modify or add anything.

assert_role = function (self, role, message)
    if not self.current_user then
        yield_error(message or err.not_logged_in)
    elseif self.current_user.role ~= role then
        yield_error(message or err.auth)
    end
end

assert_has_one_of_roles = function (self, roles)
    if not self.current_user or
        not self.current_user:has_one_of_roles(roles) then
        yield_error(err.auth)
    end
end

assert_min_role = function (self, expected_role)
    if not self.current_user:has_min_role(expected_role) then
        yield_error(err.auth)
    end
end

assert_admin = function (self, message)
    assert_role(self, 'admin', message)
end

assert_can_set_role = function (self, role)
    -- TODO use a numeric lookup table like in models >> User >> has_min_role
    local can_set = {
        admin = {
            admin =
                { admin = true, moderator = true, reviewer = true,
                    standard = true, banned = true },
            moderator =
                { admin = true, moderator = true, reviewer = true,
                    standard = true, banned = true },
            reviewer =
                { admin = true, moderator = true, reviewer = true,
                    standard = true, banned = true },
            standard =
                { admin = true, moderator = true, reviewer = true,
                    standard = true, banned = true },
            banned =
                { admin = true, moderator = true, reviewer = true,
                    standard = true, banned = true }
        },
        moderator = {
            admin = {}, moderator = {},
            reviewer =
                { moderator = true, reviewer = true, standard = true,
                    banned = true },
            standard =
                { moderator = true, reviewer = true, standard = true,
                    banned = true },
            banned =
                { moderator = true, reviewer = true, standard = true,
                    banned = true }
        },
        reviewer = {
            admin = {}, moderator = {}, reviewer = {}, banned = {},
            standard = { reviewer = true, standard = true }
        },
        standard =
            { admin = {}, moderator = {}, reviewer = {}, standard = {},
                banned = {} },
        banned =
            { admin = {}, moderator = {}, reviewer = {}, standard = {},
                banned = {} }
    }
    if not can_set[self.current_user.role][self.queried_user.role][role] then
        yield_error(err.auth)
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

assert_users_have_email = function (self, message)
    local users =
        Users:select(
            'where email = ?',
            self.params.email or '',
            { fields = 'username' })
    if users and users[1] then
        return users
    else
        yield_error(message or err.nonexistent_email)
    end
end


-- Projects

assert_can_share = function (self, project)
    if not project then yield_error(err.nonexistent_project) end
    if (project.username ~= self.current_user.username) then
        assert_min_role(self, 'reviewer')
    end
end

assert_can_delete = function (self, project)
    if not project then yield_error(err.nonexistent_project) end
    if (project.username ~= self.current_user.username) then
        assert_min_role(self, 'moderator')
    end
end

assert_project_exists = function (self, project)
    if not project then yield_error(err.nonexistent_project) end
end

-- Tokens

check_token = function (self, token, purpose, on_success)
    if token then
        local query =
            db.select("date_part('day', now() - ?::timestamp)",
                token.created)[1]
        if query.date_part < 4 and token.purpose == purpose then
            -- TODO: use self.queried_user and assert matches token.username
            local user = Users:find({ username = token.username })
            token:delete()
            return on_success(user)
        elseif token.purpose ~= purpose then
            -- We simply ignore tokens with different purposes
            return htmlPage(self, 'Invalid token', '<p>' ..
                err.invalid_token.msg .. '</p>')
        else
            -- We delete expired tokens with 'verify_user' purpose
            token:delete()
            return htmlPage(self, 'Expired token', '<p>' ..
                err.expired_token.msg .. '</p>')
        end
    else
        -- This token does not exist anymore, or never existed
        return htmlPage(self, 'Invalid token', '<p>' ..
            err.invalid_token.msg .. '</p>')
    end
end

find_token = function (username, purpose)
    return Tokens:find({ username = username, purpose = purpose})
end

--- Creates a token and sends an email
-- @param self: request object
-- @param purpose string: token purpose and route name
-- @param username string
-- @param email string
create_token = function (self, purpose, user)
    local token_value

    -- First check whether there's an existing token for the same user and
    -- purpose. If we find it, we'll just reset its creation date and reuse it.
    local existing_token = find_token(user.username, purpose)

    if existing_token then
        token_value = existing_token.value
        existing_token:update({
            created = db.format_date()
        })
    else
        token_value = secure_token()
        Tokens:create({
            username = user.username,
            created = db.format_date(),
            value = token_value,
            purpose = purpose
        })
    end
    send_mail(
        user.email,
        mail_subjects[purpose] .. user.username,
        mail_bodies[purpose],
        self:build_url(self:url_for(
            purpose,
            {
                username = url.build_path({ user.username }),
                token = url.build_path({ token_value })
            }
        ))
    )
end

-- Collections

can_edit_collection = function (self, collection)
    if self.current_user == nil then
        return false
    end

    -- Users can edit their own collections
    local can_edit = collection.creator_id == self.current_user.id

    -- Find out whether user is in the editors array
    if collection.editor_ids then
        for _, editor_id in pairs(collection.editor_ids) do
            if can_edit then return true end
            can_edit = can_edit or (editor_id == self.current_user.id)
        end
    end

    return can_edit
end

assert_collection_exists = function (self)
    local creator = Users:find({ username = self.params.username })
    if not creator then
        yield_error(err.nonexistent_collection)
    end
    local collection = Collections:find(creator.id, self.params.name)

    if not collection then
        yield_error(err.nonexistent_collection)
    end

    return collection
end

assert_can_view_collection = function (self, collection)
    if (not collection.shared and not collection.published
            and not (
                users_match(self) or
                can_edit_collection(self, collection))
            ) then
        yield_error(err.nonexistent_collection)
    end
end

assert_can_add_project_to_collection = function (self, project, collection)
    -- Admins can add any project to any collection.
    if self.current_user:isadmin() then return end

    -- Users can add their own published projects to "free for all" collections
    if collection.free_for_all and
            project.username == self.current_user.username then
        if not project.ispublished then
            yield_error(err.unpublished_project_in_ffa_collection)
        else
            return
        end
    end

    -- Users can add their own projects and published projects to collections
    -- they can edit
    if can_edit_collection(self, collection) then
        return project.username == self.current_user.username or
            project.ispublished
    end

    yield_error(err.nonexistent_project)
end

assert_can_remove_project_from_collection =
    function (self, collection, project)
        -- Admins can remove any project from any collection.
        if self.current_user:isadmin() then return end
        if not (can_edit_collection(self, collection) or
                project.username == self.current_user.username) then
            yield_error(err.auth)
        end
end

assert_project_not_in_collection = function (self, project, collection)
    -- We can't add a project twice to a collection
    if CollectionMemberships:find(collection.id, project.id) then
        yield_error(err.project_already_in_collection)
    end
end

assert_can_create_colletion = function (self)
    -- Spammer guard.
    -- Non-validated users and users without at least a project can't create
    -- collections.
    if not self.current_user.verified then
        yield_error(err.nonvalidated_user)
    end
    project_count =
        Projects:select(
            'where username = ?',
            self.current_user.username,
            { fields = 'count(*) as count'}
            )[1].count
    if (project_count == 0) then
        yield_error(err.user_too_new)
    end
end

-- Project name filter
-- Matches project names that are typical in courses like BJC or Teals.
course_name_filter = function ()
    local expressions = {
        '^[0-9]+\\.[0-9]+',
        'u[0-9]+l[0-9]+',
        'm[0-9]+l[0-9]+',
        '^lab *[0-9]+',
        '^unit([0-9]+| )',
        '^ap ',
        'create *task',
        '^coin *flip',
        'week *[0-9]+',
        'lesson *[0-9]+',
        'task *[0-9]+',
        'do now'
    }
    local filter = ''
    for _, expression in pairs(expressions) do
        filter = filter .. ' and (projectname !~* ' ..
            "'" .. expression .. "')"
    end
    return filter
end

-- Rate limiting
rate_limit = function (self)
    if ngx.shared.session_cache:get(self.session.access_id) or
            (self.session.access_id == nil) then
        self.session.first_access = os.time()
        self.session.access_id = socket.gettime() .. '-' .. math.random()
        yield_error(err.session_reused)
        exceptions.rvn:captureMessage(err.session_reused)
    else
        ngx.shared.session_cache:set(self.session.access_id, true)
        self.session.access_id = socket.gettime() .. '-' .. math.random()
    end

    if ((os.time() - self.session.first_access) < 2) then
        yield_error(err.too_soon)
        exceptions.rvn:captureMessage(err.too_soon)
    end

    if self.session.current_access_time == nil then
        self.session.current_access_time = os.time()
        return
    end
    self.session.previous_access_time = self.session.current_access_time
    self.session.current_access_time = os.time()

    if self.session.allowed_time_difference == nil then
        self.session.allowed_time_difference = 2
    end

    local time_diff =
        (self.session.current_access_time - self.session.previous_access_time)
    if time_diff < self.session.allowed_time_difference then
        -- you're being punished with double time, capped at 30 secs
        self.session.allowed_time_difference =
            math.min(self.session.allowed_time_difference * 2, 30)
        yield_error(err.too_fast)
        exceptions.rvn:captureMessage(err.too_fast)
    else
        self.session.allowed_time_difference = 2
    end
end

-- Block certain requests from being made using Tor
prevent_tor_access = function (self)
    local file = io.open('lib/torbulkexitlist', 'r')
    local tor_ips = file:read('all')
    local ip = ngx.var.remote_addr
    if tor_ips:find(ip) then
        yield_error(err.tor_not_allowed)
    end
end
