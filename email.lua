-- Email Functionality
-- ===================
--
-- Written by Michael Ball
--
-- Copyright (C) 2018 by Michael Ball
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

local config = package.loaded.config

--[[
Email functionality.
We are using a hack by Michael Aschauer (@backface), but should move towards an API-based service.
]]

local function send_smtp_mail(rcpt, subject, body)
    local socket = require 'socket'
    local base = _G
    -----------------------------------------------------------------------------
    -- Mega hack. Don't try to do this at home.
    -----------------------------------------------------------------------------
    -- we can't yield across calls to protect on Lua 5.1, so we rewrite it with
    -- coroutines
    -- make sure you don't require any module that uses socket.protect before
    -- loading our hack

    if string.sub(base._VERSION, -3) == "5.1" then
        local function _protect(co, status, ...)
            if not status then
                local msg = ...
                if base.type(msg) == 'table' then
                    return nil, msg[1]
                else
                    base.error(msg, 0)
                end
            end
            if coroutine.status(co) == "suspended" then
                return _protect(co, coroutine.resume(co, coroutine.yield(...)))
            else
                return ...
            end
        end

        function socket.protect(f)
            return function(...)
                local co = coroutine.create(f)
                return _protect(co, coroutine.resume(co, ...))
            end
        end
    end

    local smtp = require 'socket.smtp'
    local ssl = require 'ssl'
    local https = require 'ssl.https'
    local ltn12 = require 'ltn12'

    function sslCreate()
        local sock = socket.tcp()
        return setmetatable({
            connect = function(_, host, port)
                local r, e = sock:connect(host, port)
                if not r then return r, e end
                sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
                return sock:dohandshake()
            end
        }, {
            __index = function(t,n)
                return function(_, ...)
                    return sock[n](sock, ...)
                end
            end
        })
    end


    local msg = {
        headers = {
            from = config.mail_from_name .. " <" .. config.mail_from .. ">",
            to = rcpt,
            subject = subject
        },
        body = body
    }

    local ok, err = smtp.send {
        from = config.mail_from,
        rcpt = rcpt,
        source = smtp.message(msg),
        user = config.mail_user,
        password = config.mail_password,
        server = config.mail_server,
        port = 465,
        create = sslCreate
    }

    return ok, err
end

-- local Mailgun = require("mailgun").Mailgun
-- local mailer = Mailgun({
--     domain = config.mailgun.domain,
--     api_key = config.mailgun.api_key,
--     default_sender = 'noreply@snap-cloud.cs10.org'
-- })

local function send_email(recepient, subject, body)
    -- TODO: Use the mailgun api when SSL is figured out.
    send_smtp_mail(recepient, subject, body)
end

return {
    secure_salt = secure_salt,
    send_email = send_email
}
