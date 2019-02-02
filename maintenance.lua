-- Maintenance Mode
-- ================
--
-- Takes Snap! down for maintenance. :(
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

local app = package.loaded.app
local config = package.loaded.config

-- Enable the ability to have a maintenance mode
-- No routes are served, and a generic error is returned.
local msg = 'The Snap!Cloud is currently down for maintenance.'
app:get('/*', function(self)
    return errorResponse(msg, 500)
end)
    return app
end
