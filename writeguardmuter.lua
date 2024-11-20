-- _G Write guard log spam hack
-- ============================
--
-- Silences annoying '_G write guard' warning messages on logs. Not the best way
-- to handle this.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2020 by Bernat Romagosa and Michael Ball
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

local selectors = {
    'lfs', 'lpeg', 'socket', 'ltn12',

    'create_redirect_url', 'build_payload', 'extract_payload',

    'tbl', 'APIController', 'CollectionController', 'ProjectController',
    'UserController', 'SiteController',

    'random_password', 'secure_token', 'secure_salt', 'jsonResponse',
    'xmlResponse', 'okResponse', 'errorResponse', 'html_message_page', 'cors_options',
    'rawResponse', 'TIMEOUT', 'mail_bodies', 'mail_subjects', 'send_mail',
    'err', 'assert_all', 'assert_logged_in', 'assert_role',
    'assert_has_one_of_roles', 'assert_admin', 'assert_can_set_role',
    'users_match', 'assert_users_match', 'assert_user_exists',
    'assert_user_can_create_accounts', 'assert_can_view_project',
    'assert_users_have_email', 'assert_project_exists', 'check_token',
    'create_token', 'assert_collection_exists',
    'assert_can_view_collection', 'assert_can_add_project_to_collection',
    'assert_can_remove_project_from_collection',
    'assert_project_not_in_collection', 'assert_can_create_collection',
    'course_name_filter', 'hash_password', 'create_signature', 'find_token',
    'rate_limit', 'prevent_tor_access', 'assert_min_role', 'assert_can_share',
    'assert_can_delete', 'is_editor', 'old_tostring', 'debug_print'
}

for _, selector in pairs(selectors) do
    rawset(_G, selector, false)
end
