-- User controller
-- ===============
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
local capture_errors = package.loaded.capture_errors
local socket = require('socket')
local app = package.loaded.app
local json = require('cjson')

local Users = package.loaded.Users
local DeletedUsers = package.loaded.DeletedUsers
local AllUsers = package.loaded.AllUsers
local Projects = package.loaded.Projects
local Collections = package.loaded.Collections
local Tokens = package.loaded.Tokens
local Followers = package.loaded.Followers

require 'responses'
require 'validation'
require 'passwords'

UserController = {
    run_query = function (self, query)
        if not self.params.page_number then self.params.page_number = 1 end
        if not self.table then self.table = Users end

        -- Apply filters from params. They look like filter_verified=true or
        -- filter_role=reviewer, so we strip them from the "filter_" part.
        local filters = ''
        for k, v in pairs(self.params) do
            if k:find('filter_') == 1 then
                filters = filters ..
                    db.interpolate_query(' AND ' .. k:sub(8) .. ' = ?', v)
            end
        end

        local paginator = self.table:paginated(
            query ..
                (self.params.search_term and (db.interpolate_query(
                    ' AND username ILIKE ? OR email ILIKE ?',
                    '%' .. self.params.search_term .. '%',
                    '%' .. self.params.search_term .. '%')
                ) or '') ..
                (filters or '') ..
            ' ORDER BY ' .. (self.params.order or 'created_at'),
            {
                per_page = self.items_per_page or 15,
                fields = self.params.fields or '*'
            }
        )

        if not self.ignore_page_count then
            self.num_pages = paginator:num_pages()
        end

        return paginator:get_page(self.params.page_number)
    end,
    fetch = capture_errors(function (self)
        -- just to be able to reuse the existing run_query structure:
        if not self.params.order then self.params.order = 'username' end
        return UserController.run_query(self, 'WHERE true')
    end),
    zombies = capture_errors(function (self)
        self.table = DeletedUsers
        return UserController.fetch(self)
    end),
    current = capture_errors(function (self)
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
    end),
    login = capture_errors(function (self)
        assert_user_exists(self)
        local password = self.params.password
        if (hash_password(password, self.queried_user.salt) ==
                self.queried_user.password) then
            -- Check whether user has a verification token
            local token =
                Tokens:find({
                    username = self.queried_user.username,
                    purpose = 'verify_user'
                })
            if not self.queried_user.verified then
                -- Different message depending on where the login is coming
                -- from (editor vs. site)
                local message =
                    self.req and (self.req.source == 'snap')
                        and err.nonvalidated_user_plaintext
                        or err.nonvalidated_user_html
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
                    -- This should never happen
                    yield_error(message)
                end
            elseif token then
                -- User is verified but the token is still there
                token:delete()
            end
            self.session.username = self.queried_user.username
            self.cookies.persist_session = tostring(self.params.persist)
            if self.queried_user.verified then
                return okResponse('User ' .. self.queried_user.username
                        .. ' logged in')
            else
                return jsonResponse({
                    title = 'Verify your account',
                    message = 'Please verify your account within\n' ..
                        'the next ' .. self.queried_user.days_left .. ' days.',
                    redirect = self:build_url('index')
                })
            end
        else
            -- Admins can log in as other people
            assert_admin(self, err.wrong_password)
            self.session.username = self.queried_user.username
            return self:build_url('index')
        end
    end),
    logout = capture_errors(function (self)
        self.session.username = ''
        self.session.user_id = nil
        self.cookies.persist_session = 'false'
        return jsonResponse(
            { redirect = self.params.redirect or self:build_url('index') }
        )
    end),
    change_email = capture_errors(function (self)
        assert_logged_in(self)

        local user = self.queried_user or self.current_user

        if self.queried_user then
            -- we're trying to change someone else's email
            assert_min_role(self, 'moderator')
        elseif (user.password ~=
                hash_password(self.params.password, user.salt)) then
            yield_error(err.wrong_password)
        end

        user:update({ email = self.params.email })

        return jsonResponse({
            title = 'Email changed',
            message = 'Email has been updated.',
            redirect =
                self.params.username and
                    user:url_for('site') or
                    self:build_url('profile')
        })
    end),
    change_password = capture_errors(function (self)
        assert_logged_in(self)
        if (self.current_user.password ~=
            hash_password(self.params.old_password, self.current_user.salt))
                then
            yield_error(err.wrong_password)
        end
        self.current_user:update({
            password =
                hash_password(self.params.new_password, self.current_user.salt)
        })
        return jsonResponse({
            title = 'Password changed',
            message = 'Your password has been changed.',
            redirect = self:build_url('profile')
        })
    end),
    reset_password = capture_errors(function (self)
        local token =
            find_token(tostring(self.params.username), 'password_reset')
        if token then
            local minutes = db.select(
                'extract(minutes from (now()::timestamp - ?::timestamp))',
                token.created)[1].date_part
            if minutes < 15 then
                yield_error(err.too_many_password_resets)
            end
        end
        create_token(self, 'password_reset', self.queried_user)
        if self.req and (self.req.source == 'snap') then
            return okResponse()
        else
            return jsonResponse({
                title = 'Password reset',
                message = 'A link to reset your password has been sent to ' ..
                'your email account.',
                redirect = self:build_url('index')
            })
        end
    end),
    remind_username = capture_errors(function (self)
        rate_limit(self)

        local users = assert_users_have_email(self)
        local body = '<ul>'

        for _, user in pairs(users) do
            body = body .. '<li>' .. user.username .. '</li>'
        end

        body = body .. '</ul>'

        send_mail(
            self.params.email,
            mail_subjects.users_for_email,
            mail_bodies.users_for_email .. body)

        return jsonResponse({
            title = 'Username list sent',
            message = 'Email with username list sent to ' .. self.params.email,
            redirect = self:build_url('login')
        })
    end),
    delete = capture_errors(function (self)
        local user = self.queried_user or self.current_user

        if self.queried_user then
            -- we're trying to delete someone else
            assert_admin(self)
        elseif (self.current_user.password ~=
            hash_password(self.params.password, self.current_user.salt))
                then
            yield_error(err.wrong_password)
        end
        -- Do not actually delete the user; flag it as deleted.
        if not (user:update({ deleted = db.format_date() })) then
            yield_error('Could not delete user ' .. user.username)
        else
            if not self.queried_user then
                -- we've deleted ourselves, let's log out
                self.session.username = ''
                self.session.user_id = nil
                self.cookies.persist_session = 'false'
            end
            return jsonResponse({
                title = 'User deleted',
                message = 'User ' .. user.username .. ' has been removed.',
                redirect = self:build_url('index')
            })
        end
    end),
    perma_delete = capture_errors(function (self)
        assert_admin(self)
        local zombie =
            DeletedUsers:find({ username = tostring(self.params.username) })
        if zombie then
            -- Delete all follows
            db.delete(
                'followers',
                'follower_id = ? OR followed_id = ?',
                zombie.id,
                zombie.id
            )

            -- Remove user from all collections where they're editor
            db.update(
                'collections',
                { editor_ids = db.raw(db.interpolate_query(
                    'array_remove(editor_ids, ?)',
                    zombie.id))
                },
                'editor_ids @> array[?]',
                zombie.id
            )

            -- Delete all collection memberships on collections by this user
            db.delete(
                'collection_memberships',
                'collection_id IN ' ..
                    '(SELECT id FROM collections WHERE creator_id = ?)',
                zombie.id
            )

            -- Delete all collections owned by user
            db.delete('collections', { creator_id = zombie.id })

            -- Delete all flags by this user or of projects by them
            db.delete(
                'flagged_projects',
                'flagger_id = ? OR project_id IN ' ..
                    '(SELECT id FROM projects WHERE username = ?)',
                zombie.id,
                zombie.username
            )

            -- Delete all remix information involving projects by this user
            db.delete(
                'remixes',
                'original_project_id IN ' ..
                    '(SELECT id FROM projects WHERE username = ?) OR ' ..
                'remixed_project_id IN ' ..
                    '(SELECT id FROM projects WHERE username = ?)',
                zombie.username,
                zombie.username
            )

            -- Delete all tokens for this user
            db.delete('tokens', { username = zombie.username })

            -- Delete all projects by this user
            db.delete('projects', { username = zombie.username })

            -- Delete the user
            zombie:delete()

            return jsonResponse({
                title = 'User deleted',
                message = 'User ' .. tostring(self.params.username) ..
                    ' has been permanently deleted from our records.'
            })
        else
            yield_error()
        end
    end),
    revive = capture_errors(function (self)
        assert_admin(self)
        local zombie =
            DeletedUsers:find({ username = tostring(self.params.username) })
        if zombie then
            zombie:update({ deleted = db.NULL })
            local user =
                Users:find({ username = tostring(self.params.username) })
            if user then
                return jsonResponse({
                    title = 'User revived',
                    message = 'User ' .. tostring(self.params.username) ..
                        ' has been brought back from limbo.',
                    redirect = user:url_for('site')
                })
            else
                yield_error('Could not revive user')
            end
        else
            yield_error()
        end
    end),
    create = capture_errors(function (self)
        rate_limit(self)
        prevent_tor_access(self)

        -- strip whitespace *only* on create users.
        self.params.username = util.trim(tostring(self.params.username))
        validate.assert_valid(self.params, {
            { 'username', exists = true, min_length = 4,
                max_length = 200 },
            { 'password', exists = true, min_length = 6 },
            { 'email', exists = true, min_length = 5 }
        })

        local deleted_user =
            DeletedUsers:find({ username = self.params.username })
        if self.queried_user or deleted_user then
            yield_error('User ' .. self.params.username .. ' already exists');
        end

        local salt = secure_salt()
        local user = Users:create({
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
        create_token(self, 'verify_user', user)

        return jsonResponse({
            message = 'User ' .. self.params.username ..
                ' created.\nPlease check your email and validate your\n' ..
                'account within the next 3 days.\nYou can now log in.',
            title = 'Account Created',
            redirect = self:build_url('login')
        })
    end),
    create_many = capture_errors(function (self)
        -- For consistency, all users will be created or NONE will be created.
        assert_user_can_create_accounts(self)
        local users = self.params.users
        if not users then
            yield_error('Malformed JSON Provided.')
        end

        if #users > 50 then yield_error('Please limit bulk creation to 50 users.') end

        local usernames = {}
        for _, user in pairs(users) do
            table.insert(usernames, util.trim(tostring(user.username)))
        end

        -- Assert no users exist.
        local existing_users = AllUsers:find_all(usernames, 'username', { fields = 'username' })
        if #existing_users > 0 then
            usernames = {}
            local msg =
                 "No user accounts created! " ..
                #existing_users .. " users already exist. Please provide new usernames for the following users:"
            for _, user in pairs(existing_users) do
                table.insert(usernames, user.username)
            end
            return errorResponse({ errors = msg, users = usernames }, 400)
        end

        -- wrap all user creations in a transaction. No partial completions.
        db.query('BEGIN;')
        for _, user in pairs(users) do
            user.username = util.trim(tostring(user.username))
            user.password = util.trim(tostring(user.password))
            user.email = user.email or self.current_user.email
            -- TODO: This doesn't reveal which record has an invalid value...
            validate.assert_valid(user, Users.validations)

            user.created = db.format_date()
            user.salt = secure_salt()
            user.password = hash_password(user.password, user.salt)
            user.verified = true
            user.role = 'student'
            user.creator_id = self.current_user.id
            local result = Users:create(user)
            if not result then
                db.query('ROLLBACK;')
                return errorResponse('User ' .. user.username .. ' errored on creation.')
            end
        end
        local result = db.query('COMMIT;')
        -- TODO: Error Handling.
        return jsonResponse({
            message = #usernames .. ' users created.',
            users = usernames
        })
    end),
    become = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        if self.queried_user then
            -- you can't become someone with a higher role than yours
            if Users.roles[self.current_user.role] <
                    Users.roles[self.queried_user.role] then
                yield_error(err.auth)
            else
                self.session.impersonator = self.current_user.username
                self.current_user = self.queried_user
                self.session.username = self.queried_user.username
            end
        end
        return jsonResponse({
            message = 'You are now ' .. self.queried_user.username,
            title = 'Impersonation',
            redirect = self:build_url('profile')
        })
    end),
    unbecome = capture_errors(function (self)
        if self.session.impersonator then
            self.session.username = self.session.impersonator
            self.current_user =
                Users:find({ username = self.session.impersonator})
            self.session.impersonator = nil
            return jsonResponse({
                message = 'You are now ' .. self.session.username .. ' again',
                title = 'Unimpersonation',
                redirect = self:build_url('user_admin')
            })
        end
    end),
    verify = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        if self.queried_user then
            self.queried_user:update({ verified = true })
            local token = find_token(self.queried_user.username, 'verification')
            if token then token:delete() end
        end
        return jsonResponse({
            message = 'User ' .. self.queried_user.username .. ' verified.',
            title = 'Verification',
            redirect = self.queried_user:url_for('site')
        })
    end),
    set_role = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        if self.queried_user then
            assert_can_set_role(self, self.params.role)
            self.queried_user:update({ role = self.params.role })
        end
        return jsonResponse({
            message =
                'User ' .. self.queried_user.username ..
                ' is now ' .. self.queried_user.role,
            title = 'Role set',
            redirect = self.queried_user:url_for('site')
        })
    end),
    send_email = capture_errors(function (self)
        assert_admin(self)
        if (#self.params.contents > 0) then
            send_mail(
                self.queried_user.email,
                self.params.subject or mail_subjects.generic,
                self.params.contents
            )
        else
            yield_error(err.mail_body_empty)
        end
        return jsonResponse({
            message = 'Message sent to user',
            title = 'Message sent'
        })
    end),
    resend_verification = capture_errors(function (self)
        rate_limit(self)
        assert_user_exists(self)
        if self.queried_user.verified then
            return okResponse(
                'User ' .. self.queried_user.username ..
                ' is already verified.\n' ..
                'There is no need for you to do anything.\n')
        end
        create_token(self, 'verify_user', self.queried_user)
        return okResponse(
            'Verification email for ' .. self.queried_user.username ..
            ' sent.\nPlease check your email and validate your\n' ..
            'account within the next 3 days.')
    end),
    follow = capture_errors(function (self)
        assert_user_exists(self)
        Followers:create({
            follower_id = self.current_user.id,
            followed_id = self.queried_user.id
        })
        return jsonResponse({
            message = 'Now following user ' .. self.queried_user.username,
            title = 'Follow user'
        })
    end),
    unfollow = capture_errors(function (self)
        assert_user_exists(self)
        local follow = Followers:find({
            follower_id = self.current_user.id,
            followed_id = self.queried_user.id
        })
        if follow and follow:delete() then
            return jsonResponse({
                message = 'You stopped following ' .. self.queried_user.username,
                title = 'Unfollow user'
            })
        else
            yield_error()
        end
    end),
}

app:match(
    'password_reset',
    '/password_reset/:token',
    capture_errors(
        function (self)
            -- This route is reached when a user clicks on a reset password URL
            local token = Tokens:find(self.params.token)
            return check_token(
                self,
                token,
                'password_reset',
                function (user)
                    local password, prehash = random_password()
                    user:update(
                        { password = hash_password(prehash, user.salt) }
                    )
                    send_mail(
                        user.email,
                        mail_subjects.new_password .. user.username,
                        mail_bodies.new_password .. '<p><h2>' ..
                        password .. '</h2></p>'
                    )

                    return htmlPage(
                        self,
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
        end
    )
)

app:match(
    'verify_user',
    '/verify_me/:token',
    capture_errors(
        function (self)
            local token = Tokens:find(self.params.token)
            if not token then yield_error(err.invalid_token) end
            local user = Users:find({ username = token.username })
            local user_page = function ()
                return htmlPage(
                    self,
                    'User verified | Welcome to Snap<em>!</em>',
                    '<p>Your account <strong>' .. user.username ..
                    '</strong> has been verified.</p>' ..
                    '<p>Thank you!</p>' ..
                    '<p><a href="https://snap.berkeley.edu/">' ..
                    'Take me to Snap<i>!</i></a></p>'
                )
            end

            -- Check whether user had already been verified
            if user.verified then
                return user_page()
            else
                return check_token(
                    self,
                    token,
                    'verify_user',
                    function ()
                        -- success callback
                        user:update({ verified = true })
                        self.session.verified = true
                        return user_page()
                    end
                )
            end
        end
    )
)
