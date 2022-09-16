-- Email module
-- ==========
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

local config = package.loaded.config
local mail = require "resty.mail"

local mailer, err = mail.new({
  host = config.mail_server,
  port = config.mail_smtp_port,
  starttls = config._name ~= 'development',
  username = config.mail_user,
  password = config.mail_password
})

mail_bodies = {
    verify_user = '<h1>Welcome to Snap<i>!</i></h1>' ..
                  '<p>Your new account has been created, but you still need to verify it <strong>within the next 3 days</strong> or it will be suspended.</p>' ..
                  '<p>Please follow this link to do so:</p>',
    password_reset = '<h1>Password reset requested</h1>' ..
                     '<p>We have received a password reset request for your account.</p>' ..
                     '<p>If you did not ask to reset your password, please ignore this email.</p>' ..
                     '<p>If you do want to reset your password, please follow this link <strong>within the next 3 days</strong> to do so:</p>',
    new_password = '<h1>Your new password</h1>' ..
                   '<p>A new random password has been generated for your account.</p>' ..
                   '<p><strong>Please change it immediately</strong> after logging in.</p><br/>' ..
                   '<p>Your new password is:</p>',
    project_unpublished = '<h1>Your project has been unpublished</h1>' ..
                          '<p>One of your projects has been unpublished from the Snap<em>!</em> community website by a system ',
    project_deleted = '<h1>Your project has been deleted</h1>' ..
                      '<p>One of your projects has been deleted from the Snap<em>!</em> community website by a system ',
    set_role_banned = '<h1>Your user has been banned</h1>' ..
                      '<p>You have been banned from the Snap<em>!</em> community website because of a violation of our code of conduct.</p>' ..
                      '<p>You can no longer publish any projects, but you can still make use of all the other functionalities.</p>' ..
                      '<p>All of your projects are still available to you and can be privately shared with other people.</p>',
    set_role_standard = '<h1>You are now a standard user</h1>' ..
                        '<p></p>',
    set_role_reviewer = '<h1>You are now a reviewer</h1>' ..
                        '<p>You have been appointed reviewer in the Snap<em>!</em> community website.</p>' ..
                        '<p>As a reviewer, you can now unpublish projects that violate our code of conduct.</p>' ..
                        '<p>Remember, do not abuse your newly acquired powers and use them responsibly.</p>',
    set_role_moderator = '<h1>You are now a moderator</h1>' ..
                         '<p>You have been appointed moderator in the Snap<em>!</em> community website.</p>' ..
                         '<p>As a moderator, you can now verify users manually, upgrade other users to reviewers or moderators, unpublish and delete projects that violate our code of conduct, and ban or permanently delete re-offending users.</p>' ..
                         '<p><strong>Banning a user should be your very last resort. Deleting a user should never be necessary.</strong></p>' ..
                         '<p>Remember, do not abuse your newly acquired powers and use them responsibly.</p>' ,
    set_role_admin = '<h1>You are now an administrator</h1>' ..
                     '<p>You have been appointed an administrator in the Snap<em>!</em> community website.</p>' ..
                     '<p>Remember, do not abuse your newly acquired superpowers and use them responsibly.</p>',
    users_for_email = '<h1>Users associated with to email account</h1>' ..
                      '<p>This is the list of Snap<em>!</em> usernames associated to your email account:</p>',
    bad_flag = function (user, project)
        return '<h1>Flagging System Abuse</h1>' ..
        '<p>You have flagged the project ' .. project.projectname .. ' by ' ..  project.username .. ', but we have not found it to violate any of our guidelines.</p>' ..
        '<p>Bear in mind that abusing the flagging system <em>is</em> a violation of our policy and can result in the suspension of your user account.</p>' ..
        '<p>' .. (user.bad_flags > 1 and
            ('You have already been asked to not flag legitimate projects in ' .. user.bad_flags .. ' occasions.') or
            '') ..
        'Please do not do that again.</p><br>' ..
        '<p>Thank you,</p>' ..
        '<p>The Snap<em>!</em> team</p>'
    end
}

mail_subjects = {
    verify_user = 'Verify user ',
    password_reset = 'Reset password for ',
    new_password = 'New password for ',
    project_unpublished = 'Project unpublished: ',
    project_deleted = 'Project deleted: ',
    set_role_banned = 'User banned: ',
    set_role_standard = 'You are now a standard user, ',
    set_role_reviewer = 'You are now a reviewer, ',
    set_role_moderator = 'You are now a moderator, ',
    set_role_admin = 'You are now an administrator, ',
    users_for_email = 'Users associated to your email account',
    bad_flag = 'Flagged project'
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
