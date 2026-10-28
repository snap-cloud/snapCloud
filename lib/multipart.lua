-- Multipart form parsing from a buffered request body
-- ====================================================
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

-- Lapis parses multipart/form-data with lua-resty-upload, which reads the
-- raw request socket and fails over HTTP/2. This parses the body nginx has
-- already buffered and returns the same shape Lapis does: plain fields as
-- strings, file fields as { name, filename, content, ['content-type'] }.

local multipart = {}

local function unquote(value)
    return value and value:match('^"(.*)"$') or value
end

multipart.parse = function (body, content_type)
    local boundary = content_type and
        unquote(content_type:match('[Bb]oundary=([^;]+)'))
    local params = {}
    if not body or not boundary then return params end

    local delimiter = '--' .. boundary
    local position = body:find(delimiter, 1, true)
    while position do
        local part_start = position + #delimiter
        if body:sub(part_start, part_start + 1) == '--' then break end
        local next_position = body:find('\r\n' .. delimiter, part_start, true)
        if not next_position then break end
        local part = body:sub(part_start, next_position - 1)
        local header_end = part:find('\r\n\r\n', 1, true)
        if header_end then
            local headers = part:sub(1, header_end - 1)
            local field = { content = part:sub(header_end + 4) }
            for name, value in headers:gmatch('\r?\n?([%w%-]+):%s*([^\r\n]*)') do
                field[name:lower()] = value
            end
            for key, value in (field['content-disposition'] or ''):gmatch(';%s*(%w+)=("[^"]*")') do
                field[key] = unquote(value)
            end
            if field.name then
                params[field.name] = field['content-type'] and field or field.content
            end
        end
        position = next_position + 2
    end
    return params
end

return multipart
