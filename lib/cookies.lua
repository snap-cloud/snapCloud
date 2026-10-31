-- Cookie names, attributes, and the __Host- session cookie migration
-- ====================================================================
--
-- Written by Michael Ball
--
-- Copyright (C) 2026 by Michael Ball
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
--
--
-- Why this file exists
-- --------------------
--
-- We want the session cookie to carry the `__Host-` prefix. A browser only
-- accepts a cookie with that name prefix when it arrives over HTTPS, with
-- `Path=/`, and WITHOUT a `Domain` attribute. In exchange, nothing except
-- this exact origin can create or overwrite it: not a sibling subdomain,
-- not a network attacker on the plain-HTTP extensions.snap.berkeley.edu
-- host. That closes session fixation and login-CSRF via planted cookies.
--
-- Lapis (through 1.20.0) gets in the way in two places:
--
-- 1. `lapis.request` writes every Set-Cookie header as
--        url.escape(name) .. "=" .. url.escape(value)
--    using LuaSocket's url.escape, which percent-encodes everything outside
--    [A-Za-z0-9_]. The `-` in `__Host-snapsession` becomes `%2d`, so the
--    browser sees an ordinary cookie called `__Host%2dsnapsession` and
--    applies no prefix rules at all. Lapis then unescapes names when it
--    parses the Cookie header, so the app round-trips and never notices.
--    We replace `Request.support.write_cookies` below with a copy of the
--    lapis function that writes names made of RFC 6265 token characters
--    verbatim. `support` is a class-level table lapis has dispatched through
--    since 2016; if a future lapis renames it, this file fails loudly at
--    startup instead of silently regressing. Delete the override once
--    upstream writes names unescaped.
--
-- 2. Our old `cookie_attributes` always added `Domain=<host>`, which the
--    `__Host-` rules forbid, and which also made the cookie readable and
--    writable from every subdomain. The attribute policy now lives here and
--    omits Domain, so cookies are host-only.

local url = require('socket.url')
local Request = require('lapis.request')
local config = package.loaded.config

local cookies = {}

-- RFC 6265 "token" characters: the set a cookie name may be made of.
local COOKIE_NAME = "^[%w!#$%%&'*+%-%.%^_`|~]+$"

-- Same lifetime as before: 35 days, continually extended by any request
-- that changes the session.
cookies.SESSION_MAX_AGE = 35 * 24 * 60 * 60

-- 1. Write cookie names verbatim. This mirrors `write_cookies` in
-- lapis/request.moon (v1.20.0) line for line, except for the name.
assert(type(Request.support) == 'table' and
       type(Request.support.write_cookies) == 'function',
    'lib/cookies.lua: lapis.request no longer exposes support.write_cookies; ' ..
    'check whether this override is still needed')

Request.support.write_cookies = function (self)
    if not next(self.cookies) then return end
    for name, value in pairs(self.cookies) do
        local wire_name = name:match(COOKIE_NAME) and name or url.escape(name)
        local cookie = wire_name .. '=' .. url.escape(value)
        local extra = self.app.cookie_attributes(self, name, value)
        if extra then
            cookie = cookie .. '; ' .. extra
        end
        self.res:add_header('Set-Cookie', cookie)
    end
end

-- 2. Attributes for every cookie we set. Lapis calls app.cookie_attributes
-- once per cookie with its name.
--
-- Cookies are 'session cookies' unless they have an expiration date. Any
-- update to `self.session.x` re-sends the cookie and so extends its life.
-- No Domain attribute: __Host- forbids it, and a host-only cookie is still
-- sent to the cloud from any origin that uses credentialed requests.
function cookies.attributes(self, name)
    local attributes = 'Path=/;'
    if config._name == 'development' then
        attributes = attributes .. ' HttpOnly; SameSite=Lax;'
    else
        -- SameSite must be None so the editor on other origins can use the
        -- API with credentials. CSRF is handled by the Origin check in app.lua.
        attributes = attributes .. ' Secure; HttpOnly; SameSite=None;'
    end
    if self.session.persist_session == 'true' then
        attributes = 'Max-Age=' .. cookies.SESSION_MAX_AGE .. '; ' .. attributes
    end
    return attributes
end

return cookies
