-- Email module
-- ==========
--
-- Written by Bernat Romagosa
--
-- Copyright (C) 2018 by Bernat Romagosa
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

local config = package.loaded.config
local mail = require "resty.mail"

local mailer, err = mail.new({
  host = config.mail_server,
  port = 587,
  starttls = true,
  username = config.mail_user,
  password = config.mail_password
})

mail_bodies = {
    signup = '<h1>Welcome to Snap<i>!</i></h1>' ..
             '<p>Your new account has been created, but you still need to verify it within the next 24 hours.</p>' ..
             '<p>Please follow this link to do so:</p>',
    password_reset = '<h1>Password reset requested</h1>' ..
                     '<p>We have received a password reset request for your account.</p>' ..
                     '<p>If you did not ask for a password reset, please ignore this email.</p>' ..
                     '<p>If you do want to reset your password, please follow this link to do so:</p>'
}

send_mail = function (address, subject, html, url)
    if url then
        html = html .. '<p><a href="' .. url .. '">' .. url .. '</a></p>'
    end
    local ok, err = mailer:send({
        from = config.mail_from_name .. ' <' .. config.mail_from .. '>',
        to = { address },
        subject = subject,
        html = html .. config.mail_footer
    })
    return err or ok
end
