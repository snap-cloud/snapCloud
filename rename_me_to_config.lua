-- You need to rename this file to config.lua and set the proper
-- password and database name, as well as a secret phrase for
-- Lapis session encryption.

local config = require('lapis.config')

config({'development', 'production'}, {
    postgres = {
        host = '127.0.0.1:5432',
        user = 'snap',
        password = 'postgres_password',
        database = 'postgres_database'
    },
    site_name = 'Snap Cloud',
    port = 8080,
    ssl_port = 443,
    enable_https = true,
    num_workers = 1,
    code_cache = 'off'
    session_name = 'snapsession',
    secret = 'a super secret phrase you should never ever make public',

    -- Change to the relative (or absolute) path of your disk storage
    -- directory.  Note that the user running Lapis needs to have
    -- read & write permissions to that path.
    store_path = 'store'

     -- for sending email
    mail_server = "",
    mail_user     = "",
    mail_password = "",
    mail_from = "",
    mail_footer = ""
})

config('production', {
    num_workers = 12,
    code_cache = 'on',
    store_path = '/opt/snap'
})
