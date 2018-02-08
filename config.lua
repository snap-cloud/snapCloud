-- You need to rename this file to config.lua and set the proper
-- password and database name, as well as a secret phrase for
-- Lapis session encryption.

local config = require('lapis.config')
local port = os.getenv('PORT') or 8080

-- TODO: Pull out the different pieces into a dev only section
config({'development', 'production'}, {
    use_daemon = 'off',
    postgres = {
        host = os.getenv('DATABASE_URL') or '127.0.0.1:5432',
        user = os.getenv('DATABASE_USERNAME') or 'snap',
        password = os.getenv('DATABASE_PASSWORD') or 'snap-cloud-password',
        database = os.getenv('DATABASE_NAME') or 'snap_cloud'
    },
    site_name = 'dev | Snap Cloud',
    hostname = 'localhost',
    port = port,
    ssl_port = os.getenv('SSL_PORT') or 443,
    ssl_cert_name = os.getenv('SSL_CERT_NAME') or 'home',
    enable_https = false,
    num_workers = 1,
    code_cache = 'off',

    session_name = 'snapsession',
    secret = os.getenv('SESSION_SECRET_BASE') or 'this is a secret',

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

    measure_performance = true,

    cors_domains = {
        'localhost:' .. port,
        'snap.berkeley.edu'
    }
})

config('production', {
    use_daemon = 'on',
    postgres = {
        host = os.getenv('DATABASE_URL'),
        user = os.getenv('DATABASE_USERNAME'),
        password = os.getenv('DATABASE_PASSWORD'),
        database = os.getenv('DATABASE_NAME')
    },
    port = port or 80,
    site_name = 'Snap Cloud',
    hostname = 'snap-clous.cs10.org',
    ssl_cert_name = os.getenv('SSL_CERT_NAME') or 'snap-cloud.cs10.org',
    enable_https = true,
    secret = os.getenv('SESSION_SECRET_BASE'),
    num_workers = 12,
    code_cache = 'on',

    --- TODO: See if we can turn this on without a big hit
    measure_performance = false,

    cors_domains = {
        'snap.berkeley.edu',
        -- MIRRORS
        'cs10.org',
        'bjc.edc.org',
        'web.media.mit.edu',
        'byob.eecs.berkeley.edu',
        -- RESEARCH PROJECTS
        'eliza.csc.ncsu.edu',
        'lambda.cs10.org',
        -- EDX (sad)
        'courses.edge.edx.org',
        'courses.edx.org',
        'd37djvu3ytnwxt.cloudfront.net',
        'preview.courses.edge.edx.org',
        'preview.courses.edx.org',
        'preview.edge.edx.org',
        'preview.edx.org',
        'studio.edge.edx.org',
        'studio.edx.org',
        'edge.edx.org'
    },

    store_path = 'store'
})
