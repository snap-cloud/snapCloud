-- Project XML metadata rewriting
-- ==============================
--
-- Patches the DB title and notes into a project.xml string as it is served,
-- without parsing it, so the stored file is never touched.
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

local project_xml = {}

-- Mirrors XML_Element.prototype.escape in Snap!'s xml.js.
local function escape(text, keep_quotes)
    return (tostring(text):gsub('[\'"<>&\n~]', function (char)
        if char == "'" then return '&apos;' end
        if char == '"' then return keep_quotes and char or '&quot;' end
        if char == '<' then return '&lt;' end
        if char == '>' then return '&gt;' end
        if char == '&' then return '&amp;' end
        if char == '\n' then return '&#xD;' end
        return '&#126;'
    end))
end

project_xml.escape = escape

-- Replaces the name="..." attribute of the tag starting at tag_start.
local function set_name_attribute(xml, tag_start, name)
    local tag_end = xml:find('>', tag_start, true)
    if not tag_end then return xml end
    local tag = xml:sub(tag_start, tag_end)
    local attr_start, attr_end = tag:find('%sname="[^"]*"')
    if not attr_start then return xml end
    local attribute = ' name="' .. escape(name) .. '"'
    if tag:sub(attr_start, attr_end) == attribute then return xml end
    return xml:sub(1, tag_start - 1) ..
        tag:sub(1, attr_start - 1) .. attribute .. tag:sub(attr_end + 1) ..
        xml:sub(tag_end + 1)
end

-- Replaces the <notes> element directly following the tag at tag_start.
local function set_notes(xml, tag_start, notes)
    local tag_end = xml:find('>', tag_start, true)
    if not tag_end then return xml end
    local open_start, open_end = xml:find('^%s*<notes>', tag_end + 1)
    if not open_start then return xml end
    local close_start = xml:find('</notes>', open_end + 1, true)
    if not close_start then return xml end
    local contents = escape(notes, true)
    if xml:sub(open_end + 1, close_start - 1) == contents then return xml end
    return xml:sub(1, open_end) .. contents .. xml:sub(close_start)
end

-- Writes name and notes (each when not nil) into <project> and the first <scene>.
function project_xml.rewrite_metadata(xml, name, notes)
    if type(xml) ~= 'string' then return xml end
    local project_start = xml:find('<project[%s>]')
    if not project_start then return xml end

    local function rewrite(tag_start)
        if name ~= nil then xml = set_name_attribute(xml, tag_start, name) end
        if notes ~= nil then xml = set_notes(xml, tag_start, notes) end
    end

    rewrite(project_start)
    local scene_start = xml:find('<scene[%s>]', project_start)
    if scene_start then rewrite(scene_start) end
    return xml
end

return project_xml
