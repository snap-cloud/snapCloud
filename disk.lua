-- Disk storage utils
-- ==================
--
-- written by Bernat Romagosa
--
-- Copyright (C) 2017 by Bernat Romagosa
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


-- we store max 1000 projects per dir

local config = require("lapis.config").get()

directoryForId = function (id)
    return config.store_path .. '/' .. math.floor(id / 1000) .. '/' .. id
end

saveToDisk = function (id, filename, contents)
    local dir = directoryForId(id)
    os.execute('mkdir -p ' .. dir)
    local file = io.open(dir .. '/' .. filename, 'w+')
    file:write(contents)
    file:close()
end

retrieveFromDisk = function (id, filename)
    local dir = directoryForId(id)
    local file = io.open(dir .. '/' .. filename, 'r')
    if (file) then
        local contents = file:read("*all")
        file:close()
        return contents
    else
        return nil
    end
end

deleteDirectory = function (id)
    os.execute('rm -r ' .. directoryForId(id))
end
