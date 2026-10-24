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
--
-- Renaming the production cookie from `snapsession` to `__Host-snapsession`
-- would log everyone out, so `migrate_legacy_session` adopts a valid old
-- cookie into the new one on the first request that carries it, and tells
-- the browser to drop the old cookie. The legacy name is configured as
-- `legacy_session_name`; remove it (and the migration) once the old cookies
-- have aged out (Max-Age is 35 days for "remember me" sessions).
--
-- Staging already used the `__Host-snapsession-staging` name. On the wire
-- that was `__Host%2dsnapsession%2dstaging`, which lapis reads under the
-- same key as the corrected name, so there is nothing to migrate there:
-- staging users sign in once more and the stale cookie is ignored.

local url = require('socket.url')
local Request = require('lapis.request')
local session = require('lapis.session')
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
-- once per cookie with its name, so the legacy session cookie can be given
-- an expiry while everything else gets the normal policy.
--
-- Cookies are 'session cookies' unless they have an expiration date. Any
-- update to `self.session.x` re-sends the cookie and so extends its life.
-- No Domain attribute: __Host- forbids it, and a host-only cookie is still
-- sent to the cloud from any origin that uses credentialed requests.
function cookies.attributes(self, name)
    if name == config.legacy_session_name then
        return cookies.legacy_expiry_attributes()
    end
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

-- To delete a cookie the browser must see the same Domain and Path it was
-- set with. The old cookie used Domain=<request host>, so use that again.
function cookies.legacy_expiry_attributes()
    return 'Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; ' ..
        'Domain=' .. ngx.var.host .. '; Path=/; Secure; HttpOnly; SameSite=None;'
end

-- 3. Adopt a session from the legacy cookie name.
--
-- Call this from the before_filter before the session is used. If the new
-- cookie is absent and the old one carries a validly signed session, its
-- fields are copied into self.session, which makes lapis write them out
-- under the new name on this response. Whether or not the old cookie was
-- valid, it is expired so the browser stops sending it. Returns true when a
-- session was adopted.
function cookies.migrate_legacy_session(self)
    local legacy = config.legacy_session_name
    if not legacy or legacy == config.session_name then return false end

    local old_cookie = self.cookies[legacy]
    if not old_cookie or old_cookie == '' then return false end

    local adopted = false
    if not self.cookies[config.session_name] then
        -- get_session verifies the signature against config.secret
        local old_session = session.get_session(old_cookie)
        if type(old_session) == 'table' then
            for key, value in pairs(old_session) do
                self.session[key] = value
            end
            adopted = true
        end
    end

    -- Setting a cookie on the request object queues a Set-Cookie header;
    -- cookies.attributes() gives this name the expiry attributes.
    self.cookies[legacy] = ''
    return adopted
end

return cookies
