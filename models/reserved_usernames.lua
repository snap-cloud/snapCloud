-- Reserved Usernames
-- ==================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2023 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local reserved_names = {}

reserved_names['system'] = true
reserved_names['current'] = true
reserved_names['admin'] = true
reserved_names['adminstrator'] = true
reserved_names['cloud'] = true
reserved_names['mod'] = true
reserved_names['mods'] = true
reserved_names['moderator'] = true
reserved_names['moderators'] = true
reserved_names['reviewer'] = true
reserved_names['reviewers'] = true
reserved_names['root'] = true
reserved_names['superuser'] = true
reserved_names['snapcloud'] = true
reserved_names['snap'] = true
reserved_names['snap.*cloud'] = true
reserved_names['snap.*cloud.*'] = true

return reserved_names
