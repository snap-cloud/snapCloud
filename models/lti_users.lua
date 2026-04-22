-- Snap!Cloud LTI Users Model
-- ==========================
--
-- Linkage between an LTI subject (the `sub` claim within a specific platform)
-- and a Snap!Cloud user. Multiple LTI identities may link to the same user.
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2026 by Bernat Romagosa and Michael Ball
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

local Model = package.loaded.Model

local LtiUsers = Model:extend('lti_users', {
    timestamp = true,
    relations = {
        { 'platform', belongs_to = 'LtiPlatforms', key = 'platform_id' },
        { 'user', belongs_to = 'Users', key = 'user_id' }
    }
})

return LtiUsers
