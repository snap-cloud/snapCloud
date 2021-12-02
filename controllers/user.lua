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
        UserController.run_query(self, 'WHERE true')
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
                return 'index'
            else
                return jsonResponse(
                    { days_left = self.queried_user.days_left })
            end
        else
            -- Admins can log in as other people
            assert_admin(self, 'wrong password')
            self.session.username = self.queried_user.username
            return 'index'
        end
    end,
    logout = function (self)
        self.session.username = ''
        self.session.user_id = nil
        self.cookies.persist_session = 'false'
        return { redirect_to = self:build_url('/') }
    end
}
