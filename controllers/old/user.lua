-- User API controller
-- ===================
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

local util = package.loaded.util
local validate = package.loaded.validate
local db = package.loaded.db
local cached = package.loaded.cached
local yield_error = package.loaded.yield_error
local socket = require('socket')

local Users = package.loaded.Users
local DeletedUsers = package.loaded.DeletedUsers
local Projects = package.loaded.Projects
local Collections = package.loaded.Collections
local Tokens = package.loaded.Tokens

require 'responses'
require 'validation'
require 'passwords'

UserController = {
    GET = {
        current_user = function (self)
            -- GET /users/c
            -- Description: Get the currently logged user's username and
            --              credentials.
            if self.current_user then
                self.session.verified = self.current_user.verified
                self.session.user_id = self.current_user.id
            elseif self.session.username == '' then
                self.session.role = nil
                self.session.verified = false
                self.session.user_id = nil
            end

            if (self.session.first_access == nil) then
                self.session.first_access = os.time()
            end

            if (self.session.access_id == nil) then
                -- just to uniquely identify the session
                self.session.access_id =
                    socket.gettime() .. '-' .. math.random()
            end

            return jsonResponse({
                username = self.session.username,
                role = self.session.role,
                verified = self.session.verified,
                id = self.session.user_id
            })
        end,
        user = function (self)
            -- GET /users/:username
            -- Description: Get info about a user
            if not users_match(self) then assert_admin(self) end
            return jsonResponse(
                db.query(
                    [[SELECT
                        users.username, users.created, users.role, users.email,
                        users.verified, users.id, count(projects.projectname)
                            AS project_count
                    FROM active_users AS users
                    LEFT JOIN active_projects AS projects
                        ON projects.username = users.username
                    WHERE users.username = ?
                    GROUP BY
                        users.username, users.created, users.role, users.email,
                        users.verified, users.id]],
                    self.params.username
                )[1]
            )
        end,

        password_reset = function (self)
            -- GET /users/:username/password_reset(/:token)
            -- Description: Check whether a reset password token is correct,
            --              and reset a user's password if so.
            return check_token(
                self.params.token,
                'password_reset',
                function (user)
                    local password, prehash = random_password()
                    user:update({ password = hash_password(prehash, user.salt) })
                    send_mail(
                        user.email,
                        mail_subjects.new_password .. user.username,
                        mail_bodies.new_password .. '<p><h2>' ..
                            password .. '</h2></p>')

                    return html_message_page(
                        'Password reset',
                        '<p>A new random password has been generated for ' ..
                        'your account <strong>' .. user.username ..
                        '</strong> and sent to your email address. ' ..
                        'Please check your inbox.</p>' ..
                        '<p>After logging in, please proceed to <strong>' ..
                        'change your password</strong> as soon as possible.</p>'
                    )
                end
            )
        end,

        logout = function (self)
            self.session.username = ''
            self.session.user_id = nil
            self.cookies.persist_session = 'false'
            return { redirect_to = self:build_url('/') }
        end
    },

    POST = {
        user = function (self)
            -- POST /users/:username
            -- Description: Add or update a user. All passwords should travel
            --              pre-hashed with SHA512.
            -- Parameters:  username, password, password_repeat, email, role
            rate_limit(self)
            prevent_tor_access(self)
            if (self.current_user) then
                -- user is updating profile, or an admin is updating somebody
                -- else's profile
                if self.params.role then
                    assert_can_set_role(self, self.params.role)
                end
                if not self.queried_user then
                    self.queried_user = Users:find(
                        { username = self.params.username })
                end
                assert_user_exists(self)
                -- someone's trying to update the user's email
                if self.params.email then
                    -- they need to provide the user's password, or be an admin
                    if
                        (self.params.password == nil) or
                        (hash_password(self.params.password,
                            self.queried_user.salt) ~=
                                self.queried_user.password) then
                        assert_admin(self)
                    end
                end
                self.queried_user:update({
                    email = self.params.email or self.queried_user.email,
                    role = self.params.role or self.queried_user.role
                })
                if (self.params.role == 'banned') then
                    -- We need to unlist all projects by this user
                    db.update(
                        'projects',
                        { ispublished = false },
                        { username = self.queried_user.username })
                end
                if self.params.role then
                    send_mail(
                        self.queried_user.email,
                        mail_subjects['set_role_' .. self.params.role] ..
                            self.queried_user.username,
                        mail_bodies['set_role_' .. self.params.role])
                end
                return okResponse('Profile for user ' ..
                    self.queried_user.username .. ' updated')
            else
                -- new user
                -- Strip whitespace *only* on create users.
                self.params.username = util.trim(self.params.username)
                validate.assert_valid(self.params, {
                    { 'username', exists = true, min_length = 4,
                        max_length = 200 },
                    { 'password', exists = true, min_length = 6 },
                    { 'password_repeat', equals = self.params.password,
                        'passwords do not match' },
                    { 'email', exists = true, min_length = 5 },
                })

                local deleted_user =
                    DeletedUsers:find({ username = self.params.username })
                if self.queried_user or deleted_user then
                    yield_error('User ' .. self.params.username ..
                        ' already exists');
                end

                local salt = secure_salt()
                Users:create({
                    created = db.format_date(),
                    username = self.params.username,
                    salt = salt,
                    -- see validation.lua >> hash_password
                    password = hash_password(self.params.password, salt),
                    email = self.params.email,
                    verified = false,
                    role = 'standard'
                })

                -- Create a verify_user-type token and send an email to the user
                -- asking to verify the account.
                -- We check these on login.
                create_token(self, 'verify_user', self.params.username,
                    self.params.email)
                return okResponse(
                    'User ' .. self.params.username ..
                    ' created.\nPlease check your email and validate your\n' ..
                    'account within the next 3 days.')
            end
        end,

        new_password = function (self)
            -- POST /users/:username/newpassword
            -- Description: Sets a new password for a user. All passwords should
            --              travel pre-hashed with SHA512.
            -- Parameters:  oldpassword, password_repeat, newpassword
            assert_all({'user_exists', 'users_match'}, self)

            if self.queried_user.password ~=
                hash_password(self.params.oldpassword, self.queried_user.salt)
                    then
                yield_error('wrong password')
            end

            validate.assert_valid(self.params, {
                { 'password_repeat', equals = self.params.newpassword,
                    'passwords do not match' },
                { 'newpassword', exists = true, min_length = 6 }
            })

            self.queried_user:update({
                password = hash_password(
                    self.params.newpassword, self.queried_user.salt)
            })

            return okResponse('Password updated')
        end,

        resend_verification = function (self)
            -- POST /users/:username/resendverification
            -- Description: Resends user verification email.
            rate_limit(self)
            assert_user_exists(self)
            if self.queried_user.verified then
                return okResponse(
                    'User ' .. self.queried_user.username ..
                    ' is already verified.\n' ..
                    'There is no need for you to do anything.\n')
            end
            create_token(self, 'verify_user', self.queried_user.username,
                self.queried_user.email)
            return okResponse(
                'Verification email for ' .. self.queried_user.username ..
                ' sent.\nPlease check your email and validate your\n' ..
                'account within the next 3 days.')
        end,

        password_reset = function (self)
            -- POST /users/:username/password_reset(/:token)
            -- Description: Generate a token to reset a user's password.
            -- @see validation.create_token
            assert_user_exists(self)
            local token = find_token(self.params.username, 'password_reset')
            if token then
                local epoch = db.select(
                    "extract(epoch from (now()::timestamp - ?::timestamp))",
                    token.created)[1].date_part
                local minutes = epoch / 60
                if minutes < 15 then
                    yield_error(err.too_many_password_resets)
                end
            end
            create_token(self, 'password_reset', self.params.username,
                self.queried_user.email)
            return okResponse('Password reset request sent.\n' ..
                'Please check your email.')
        end,

        login = function (self)
            -- POST /users/:username/login
            -- Description: Logs a user into the system.
            -- Body:        password
            assert_user_exists(self)

            ngx.req.read_body()
            local password = ngx.req.get_body_data()

            if (hash_password(password, self.queried_user.salt) ==
                    self.queried_user.password) then
                if not self.queried_user.verified then
                    -- Different message depending on where the login is coming
                    -- from (editor vs. site)
                    local message =
                        (ngx.var.http_referer:sub(-#'snap.html') == 'snap.html')
                            and err.nonvalidated_user_plaintext
                            or err.nonvalidated_user_html
                    -- Check whether verification token is unused and valid
                    local token =
                        Tokens:find({
                            username = self.queried_user.username,
                            purpose = 'verify_user'
                        })
                    if token then
                        local query =
                            db.select("date_part('day', now() - ?::timestamp)",
                                token.created)[1]
                        if query.date_part > 3 then
                            token:delete()
                            yield_error(message)
                        else
                            self.queried_user.days_left = 3 - query.date_part
                        end
                    else
                        yield_error(message)
                    end
                end
                self.session.username = self.queried_user.username
                self.session.role = self.queried_user.role
                self.session.verified = self.queried_user.verified
                self.session.user_id = self.queried_user.id
                self.cookies.persist_session = self.params.persist
                if self.queried_user.verified then
                    return okResponse('User ' .. self.queried_user.username
                        .. ' logged in')
                else
                    return jsonResponse(
                        { days_left = self.queried_user.days_left })
                end
            else
                -- Admins can log in as other people
                assert_admin(self, 'wrong password')
                local previous_username = self.current_user.username
                self.session.username = self.queried_user.username
                self.session.role = self.queried_user.role
                self.session.verified = self.queried_user.verified
                self.session.user_id = self.queried_user.id
                self.cookies.persist_session = 'false'
                return okResponse('User ' .. previous_username ..
                    ' now logged in as ' .. self.queried_user.username)
            end
        end,

        logout = function (self)
            -- POST /logout
            -- Description: Logs out the current user from the system.
            self.session.username = ''
            self.session.user_id = nil
            self.session.current_user = nil
            self.cookies.persist_session = 'false'
            return okResponse('logged out')
        end,
    }
}
