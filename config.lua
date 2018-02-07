-- You need to rename this file to config.lua and set the proper
-- password and database name, as well as a secret phrase for
-- Lapis session encryption.

local config = require('lapis.config')

config({'development', 'production'}, {
    postgres = {
        host = os.getenv('DATABASE_URL') or '127.0.0.1:5432',
        user = os.getenv('DATABASE_USERNAME') or 'snap',
        password = os.getenv('DATABASE_PASSWORD') or 'snap-cloud-password',
        database = os.getenv('DATABASE_NAME') or 'snap_cloud'
    },
    site_name = 'dev | Snap Cloud',
    port = os.getenv('PORT') or 8080,
    ssl_port = os.getenv('SSL_PORT') or 443,
    ssl_cert_name = os.getenv('SSL_CERT_NAME') or 'home',
    enable_ssl = false,
    num_workers = 1,
    code_cache = 'off',
    session_name = 'snapsession',
    secret = 'a super secret phrase you should never ever make public',

    -- Change to the relative (or absolute) path of your disk storage
    -- directory.  Note that the user running Lapis needs to have
    -- read & write permissions to that path.
    store_path = 'store',

    -- for sending email
    mailgun = {
        domain = os.getenv('MAILGUN_DOMAIN'),
        api_key = os.getenv('MAILGUN_API_KEY')
    },
    mail_user = os.getenv('MAIL_SMTP_USER'),
    mail_password = os.getenv('MAIL_SMTP_PASSWORD'),
    mail_server = os.getenv('MAIL_SMTP_SERVER'),
    mail_from_name = 'Snap!Cloud',
    mail_from = "noreply@snap-cloud.cs10.org",
    mail_footer = "This is a test",

    measure_performance = true

})

config('production', {
    site_name = 'Snap Cloud',
    postgres = {
        host = os.getenv('DATABASE_URL'),
        user = os.getenv('DATABASE_USERNAME'),
        password = os.getenv('DATABASE_PASSWORD'),
        database = os.getenv('DATABASE_NAME')
    },
    ssl_cert_name = os.getenv('SSL_CERT_NAME') or 'snap-cloud.cs10.org',
    enable_https = true,
    secret = os.getenv('SESSION_SECRET_BASE'),
    num_workers = 12,
    code_cache = 'on',
    store_path = '/opt/snap',

    --- TODO: See if we can turn this on without a big hit
    measure_performance = false

})
