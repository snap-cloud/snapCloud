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
local socket = require('socket')
local app = package.loaded.app

local Users = package.loaded.Users
local DeletedUsers = package.loaded.DeletedUsers
local Projects = package.loaded.Projects
local Collections = package.loaded.Collections
local Tokens = package.loaded.Tokens

require 'responses'
require 'validation'
require 'passwords'

UserController = {
    run_query = function (self, query)
        local paginator = Users:paginated(
            query ..
                (self.params.data.search_term and (db.interpolate_query(
                    ' AND username ILIKE ? OR email ILIKE ?',
                    '%' .. self.params.data.search_term .. '%',
                    '%' .. self.params.data.search_term .. '%')
                ) or '') ..
                (self.filters or '') ..
            ' ORDER BY ' .. (self.params.data.order or 'created_at'),
            {
                per_page = self.params.data.per_page or 15,
                fields = self.params.data.fields or '*'
            }
        )

        if not self.params.data.ignore_page_count then
            self.params.data.num_pages = paginator:num_pages()
        end

        self.items = paginator:get_page(self.params.data.page_number)
        self.data = self.params.data
    end,
    change_page = function (self)
        if self.params.offset == 'first' then
            self.params.data.page_number = 1
        elseif self.params.offset == 'last' then
            self.params.data.page_number = self.params.data.num_pages
        else
            self.params.data.page_number = 
                math.min(
                    math.max(
                        1,
                        self.params.data.page_number + self.params.offset),
                    self.params.data.num_pages)
        end
        self.data = self.params.data
        UserController[self.component.fetch_selector](self)
    end,
    fetch = function (self)
        -- just to be able to reuse the existing run_query structure:
        UserController.run_query(self, 'WHERE true')
    end,
    search = function (self)
        self.params.data.search_term = self.params.search_term
        UserController[self.component.fetch_selector](self)
    end,
    filter = function (self)
        if (self.params.data.filters == nil) then
            self.params.data.filters = {}
        end

        -- recast booleans
        if (self.params.value == 'true') then
            self.params.value = true
        elseif (self.params.value == 'false') then
            self.params.value = false
        end

        -- save the value and create the filters query part
        self.params.data.filters[self.params.filter] = self.params.value
        self.filters = ''
        if self.params.data.filters then
            for k, v in pairs(self.params.data.filters) do
                if (v ~= '') then
                    self.filters = self.filters ..
                        db.interpolate_query(' AND ' .. k .. ' = ?', v)
                end
            end
        end

        -- mark the selected value so the frontend will update the view
        for _, descriptor in pairs(self.params.data.filter_descriptors) do
            if (descriptor.selector == self.params.filter) then 
                for _, option in pairs(descriptor.options) do
                    if (option.value == self.params.value) then
                        option.selected = true
                    else
                        option.selected = false
                    end
                end
            end
        end
        UserController[self.component.fetch_selector](self)
    end,
    login = function (self)
        assert_user_exists(self)
        local password = self.params.password
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
            self.cookies.persist_session = tostring(self.params.persist)
            if self.queried_user.verified then
                return self:build_url('index')
            else
                return jsonResponse(
                    { days_left = self.queried_user.days_left })
            end
        else
            -- Admins can log in as other people
            assert_admin(self, err.wrong_password)
            self.session.username = self.queried_user.username
            return self:build_url('index')
        end
    end,
    logout = function (self)
        self.session.username = ''
        self.session.user_id = nil
        self.cookies.persist_session = 'false'
        return self:build_url('index')
    end,
    change_email = function (self)
        assert_logged_in(self)
        if (self.current_user.password ~=
            hash_password(self.params.password, self.current_user.salt))
                then
            yield_error(err.wrong_password)
        end
        self.current_user:update({ email = self.params.email })
        return jsonResponse({
            title = 'Email changed',
            message = 'Your email has been updated.',
            redirect = self:build_url('profile')
        })
    end,
    change_password = function (self)
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
    end,
    reset_password = function (self)
        local user = Users:find({ username = self.params.username })
        local token = find_token(self.params.username, 'password_reset')
        if token then
            local epoch = db.select(
                'extract(epoch from (now()::timestamp - ?::timestamp))',
                token.created)[1].date_part
            local minutes = epoch / 60
            if minutes < 15 then
                yield_error(err.too_many_password_resets)
            end
        end
        create_token(self, 'password_reset', user)
        return jsonResponse({
            title = 'Password reset',
            message = 'A link to reset your password has been sent to ' .. 
            'your email account.',
            redirect = self:build_url('index')
        })
    end,
}

app:match('password_reset', '/password_reset/:token', function (self)
    -- This route is reached when a user clicks on a reset password URL
    return check_token(
        self,
        'password_reset',
        function (user)
            local password, prehash = random_password()
            user:update({ password = hash_password(prehash, user.salt) })
            send_mail(
                user.email,
                mail_subjects.new_password .. user.username,
                mail_bodies.new_password .. '<p><h2>' ..
                    password .. '</h2></p>')

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
end)

