-- Response utils
-- ==============
--
-- written by Bernat Romagosa
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


-- Responses

jsonResponse = function (json)
    return {
        layout = false, 
        status = 200, 
        readyState = 4, 
        json = json or {}
    }
end

okResponse = function (message)
    return jsonResponse({ message = message })
end

rawResponse = function (contents)
    return {
        layout = false, 
        status = 200, 
        readyState = 4, 
        contents
    }
end

htmlPage = function (title, contents)
    return {
        layout = true,
        status = 200,
        readyState = 4,
        '<html><head><title>Snap! Cloud - ' .. title ..
        '</title></head><body><h1>' .. title .. '</h1>' ..
        contents .. '</body></html>'
    }
end

-- OPTIONS

cors_options = function (self)
    self.res.headers['access-control-allow-headers'] = 'Content-Type'
    self.res.headers['access-control-allow-methods'] = 'GET, POST, DELETE, OPTIONS'
    return { status = 200, layout = false }
end

