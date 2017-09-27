-- You need to rename this file to config.lua and set the proper
-- password and database name, as well as a secret phrase for
-- Lapis session encryption.

local config = require('lapis.config')

config('development', {
    postgres = {
        host = '127.0.0.1:5432',
        user = 'beetle',
        password = 'postgres_password',
        database = 'postgres_database'
    },
    site_name = 'Beetle Cloud',
    port = 8080,
    session_name = 'beetlesession',
    secret = 'a super secret phrase you should never ever make public',

     -- for sending email
    mail_server = "",
    mail_user     = "",
    mail_password = "",
    mail_from = "",
    mail_footer = ""
})

config('production', {
    postgres = {
        host = '127.0.0.1:5432',
        user = 'beetle',
        password = 'postgres_password',
        database = 'postgres_database'
    },
    code_cache = 'on',
    site_name = 'Beetle Cloud',
    port = 80,
    session_name = 'beetlesession',
    secret = 'a super secret phrase you should never ever make public',

     -- for sending email
    mail_server = "",
    mail_user     = "",
    mail_password = "",
    mail_from = "".
    mail_footer = ""
})
