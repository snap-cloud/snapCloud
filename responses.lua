-- Response utils
-- ==============
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

local tried_to_reload_post_request = [[
    You tried to reload the page of an action which updates or changes data.
    Please use the back button to return to the previous page and try again.
]]

-- local snap_respond_to = package.loaded.snap_respond_to
local function snap_snap_respond_to(handlers)
    local allowed = {}
    for k, _ in pairs(handlers) do
        table.insert(allowed, k)
    end

    -- Auto-add OPTIONS handler if not present
    if not handlers.OPTIONS then
        handlers.OPTIONS = function(self)
            self.res.headers["Allow"] = table.concat(allowed, ", ")
            return { layout = false }
        end
        table.insert(allowed, "OPTIONS")
    end

    return function(self)
        local method = self.req.method

        if handlers[method] then
            return handlers[method](self)
        end

        self.res.headers["Allow"] = table.concat(allowed, ", ")

        -- Special case: GET attempt on POST-only endpoint
        if method == "GET" and handlers.POST and not handlers.GET then
            return errorResponse(self, tried_to_reload_post_request, 405)
        end

        return errorResponse(
            self,
            "Method not allowed. Allowed methods: " .. table.concat(allowed, ", "),
            405
        )
    end
end

-- Responses

jsonResponse = function (json)
    return {
        layout = false,
        status = 200,
        readyState = 4,
        json = json or {}
    }
end

xmlResponse = function (xml)
    return {
        layout = false,
        status = 200,
        readyState = 4,
        content_type = "text/xml",
        xml
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

local html_error = function (self, error, status)
    status = status or 500
    self.locale = package.loaded.locale
    self.locale.language = self.session.locale or 'en'
    self.title = status .. ' Error'
    self.contents = error
    if status > 405 then
        self.contents = [[
            An unexpected error occurred.
            Reach out to contact@snap.berkeley.edu if you continue to experience trouble.
            Please include the details of the following message:
        ]] .. error
    end

    return { render = 'message', status = status }
end

errorResponse = function (self, err, status)
    local is_html_page = (self.req.headers['accept'] or ''):match('text/html')
    if is_html_page then
        return html_error(self, err, status)
    else
        return {
            layout = false,
            status = status or 500,
            readyState = 4,
            json = { errors = { err } }
        }
    end
end

html_message_page = function (self, title, contents)
    self.title = title
    self.contents = contents
    return { render = 'message', status = 200 }
end

export {
    snap_snap_respond_to,
    jsonResponse,
    xmlResponse,
    okResponse,
    rawResponse,
    errorResponse,
    html_message_page
}
