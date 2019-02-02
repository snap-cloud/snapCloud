-- Lapis Overrides
-- ===============
--
-- A single place where we overwrite built-in Lapis methods
--
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

-- TODO: rewrite util.slugify

-- wrap the lapis capture errors to provide our own custom error handling
-- just do: yield_error({msg = 'oh no', status = 401})
local lapis_capture_errors = package.loaded.app_helpers.capture_errors
package.loaded.capture_errors = function(fn)
    return lapis_capture_errors({
        on_error = function(self)
            local error = self.errors[1]
            if type(error) == 'table' then
                return errorResponse(error.msg, error.status)
            else
                return errorResponse(error, 400)
            end
        end,
        fn
    })
end
