-- You need to rename this file to config.lua and set the proper
-- password and database name, as well as a secret phrase for
-- Lapis session encryption.

local config = require('lapis.config')

config({'development', 'production'}, {
    postgres = {
        host = os.getenv('DATABASE_URL') or '127.0.0.1:5432',
        user = os.getenv('DATABASE_USERNAME') or 'snap',
        password = os.getenv('DATABASE_PASSWORD') or 'postgres_password',
        database = os.getenv('DATABASE_NAME') or 'postgres_database'
    },
    site_name = 'dev | Snap Cloud',
    port = 8080,
    ssl_port = 443,
    enable_https = true,
    num_workers = 1,
    code_cache = 'off',
    session_name = 'snapsession',
    secret = 'a super secret phrase you should never ever make public',

    -- Change to the relative (or absolute) path of your disk storage
    -- directory.  Note that the user running Lapis needs to have
    -- read & write permissions to that path.
    store_path = 'store',

     -- for sending email
    mail_server = "",
    mail_user     = "",
    mail_password = "",
    mail_from = "",
    mail_footer = ""
})

config('production', {
    site_name = 'Snap Cloud',
    postgres = {
        host = os.getenv('DATABASE_URL'),
        user = os.getenv('DATABASE_USERNAME'),
        password = os.getenv('DATABASE_PASSWORD'),
        database = os.getenv('DATABASE_NAME')
    },
    secret = os.getenv('SESSION_SECRET_BASE'),
    num_workers = 12,
    code_cache = 'on',
    store_path = '/opt/snap'
})
