--[[
    Shared utilities for the Snap!Cloud

]]
local config = require("lapis.config").get()

local resty_random = require ("resty.random")
local str = require("resty.string")

local function secure_salt()
    local strong_random = resty_random.bytes(16,true)
        -- attempt to generate 16 bytes of
        -- cryptographically strong random data
    while strong_random == nil do
        strong_random = resty_random.bytes(16,true)
    end

    return str.to_hex(strong_random)
end


--[[
    Email functionality.
    We are using a hack, but should move towards an API-based service.
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
    secure_salt = secure_salt
}
