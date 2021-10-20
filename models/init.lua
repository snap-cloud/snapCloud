-- Database Abstractions
-- =====================
--
-- A cloud backend for Snap!
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local db = package.loaded.db
local Model = package.loaded.Model

require 'models.users'
require 'models.projects'
require 'models.contracts'

package.loaded.BannedIPs = Model:extend(
  'banned_ips', {
      primary_key = 'ip',
      timestamp = true
  }
)

package.loaded.FlaggedProjects = Model:extend(
  'flagged_projects', {
      primary_key = 'id',
      timestamp = true
  }
)

package.loaded.Tokens = Model:extend('tokens', {
  primary_key = {'value'}
})

package.loaded.Remixes = Model:extend('remixes', {
  primary_key = {'original_project_id', 'remixed_project_id'}
})
