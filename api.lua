-- API module
-- ==========
--
-- See static/API for API description
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa and Michael Ball
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

local api_version = 'v1'

local app = package.loaded.app
local capture_errors = package.loaded.capture_errors
local json_params = package.loaded.json_params
local lapis_respond_to = package.loaded.respond_to

require 'validation'

require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'
require 'controllers.site'

-- All API routes are nested under /api/v1/. The prefix is still optional
-- in the route pattern so we don't break older clients overnight, but
-- every unprefixed hit gets logged and tagged via `respond_to` below so
-- we can audit traffic before flipping it to required.
local api_prefix = '/api/' .. api_version .. '/'
local function api_route(path) return '/(api/' .. api_version .. '/)' .. path end

-- Wrapper around lapis' respond_to that records a deprecation signal
-- whenever a route is hit without the /api/v1/ prefix:
--   * one-line WARN to the nginx error log (grep DEPRECATED_API_PREFIX)
--   * `X-Api-Deprecation` response header so external clients can detect it
-- Once production logs show zero unprefixed hits we can change api_route
-- to require the prefix and drop this wrapper.
local function respond_to(handlers)
    local wrapped = {}
    for method, handler in pairs(handlers) do
        if type(handler) == 'function' then
            wrapped[method] = function(self)
                local path = self.req.parsed_url.path or ''
                if path:sub(1, #api_prefix) ~= api_prefix then
                    local ua = self.req.headers['user-agent'] or '-'
                    ngx.log(ngx.WARN,
                        'DEPRECATED_API_PREFIX method=' .. method ..
                        ' path=' .. path ..
                        ' ua="' .. ua:gsub('"', "'") .. '"')
                    self.res.headers['X-Api-Deprecation'] =
                        'missing /api/v1 prefix; this route will require it in a future release'
                end
                return handler(self)
            end
        else
            wrapped[method] = handler
        end
    end
    return lapis_respond_to(wrapped)
end

-- API Endpoints
-- =============
app:match(api_route('version'), respond_to({
    GET = capture_errors(function (self)
        return jsonResponse({
            name = 'Snap!Cloud',
            version = api_version
        })
    end)
}))

-- TODO: After deprecating the optional 'api/v1/' prefix
-- Allow this endpoint to be accessed at /health_check as well, for easier monitoring.
-- Reports database connection pool usage, so monitors can alert before the
-- pool fills up. Our connections are counted server-side via
-- pg_stat_activity, where they carry the `snapcloud` application_name.
-- The cap comes from config.lua, see docs/DEPLOYMENT.md.
app:match(api_route('health_check'), respond_to({
    GET = capture_errors(function (self)
        local db = package.loaded.db
        local config = package.loaded.config
        local rows = db.query(
            'SELECT COUNT(*) AS count FROM pg_stat_activity ' ..
            'WHERE application_name = ?',
            config.postgres.application_name)
        local current = tonumber(rows[1].count)
        local max = config.max_db_connections
        local capacity = math.floor(current / max * 100) -- percent used
        local status, message = 'ok', 'database connection pool ok'

        if capacity > 90 then
            status = 'warning'
            message = 'Database connection pool at ' .. capacity .. '% (' ..
                current .. '/' .. max .. ' connections)'
            ngx.log(ngx.WARN, message)
            local exceptions = require('lib.exceptions')
            if exceptions.rvn then
                local _, err = exceptions.rvn:captureMessage(message,
                    { level = 'warning' })
                if err then ngx.log(ngx.ERR, err) end
            end
        end

        return jsonResponse({
            name = 'Snap!Cloud',
            status = status,
            message = message,
            current_db_connections = current,
            max_db_connections = max,
            connection_capacity = capacity,
            time = os.date('%Y-%m-%d %H:%M:%S'),
        })
    end)
}))

-- Session
-- =======
app:match(api_route('set_locale'), respond_to({
    POST = capture_errors(function (self)
        self.session.locale = self.params.locale
        return jsonResponse({ redirect = self.params.redirect })
    end)
}))

app:match(api_route('init'), respond_to({
    GET = capture_errors(function (self)
        return errorResponse(self,
            'It seems like you are trying to log in. ' ..
            'Try refreshing the page and try again. ' ..
            'This URL is internal to the Snap!Cloud.',
            400)
    end),
    POST = capture_errors(function (self)
        -- Historically /init wiped any session whose persist_session flag
        -- was 'false', which forced users who hadn't checked "remember me"
        -- out every time the editor reloaded — defeating the whole point
        -- of session cookies. Cookie persistence is now driven entirely
        -- by the absence/presence of Max-Age in app.cookie_attributes:
        -- the browser handles "should this die on browser close?" itself,
        -- and we don't second-guess it here.
        return okResponse()
    end)
}))

-- Current user
-- ============
app:get(api_route('users/c'), respond_to({  -- backwards compatibility
    GET = UserController.current
}))

app:match(api_route('my_user'), respond_to({
    GET = UserController.current,
    DELETE = UserController.delete
}))

app:match(api_route('logout'), respond_to({
    POST = UserController.logout,
    DELETE = UserController.logout
}))

app:match(api_route('unbecome'), respond_to({
    POST = UserController.unbecome
}))

-- TODO: Deprecate this route
app:match(api_route('change_my_email'), respond_to({
    POST = UserController.change_email
}))

app:match(api_route('change_my_password'), respond_to({
    POST = UserController.change_password
}))

app:match(api_route('users/:username/newpassword'), respond_to({
    POST = capture_errors(function (self)
        self.params.old_password = self.params.oldpassword
        self.params.new_password = self.params.newpassword
        return UserController.change_password(self)
    end)
}))

-- Other users
-- ===========
app:match(api_route('signup'), respond_to({
    POST = UserController.create
}))

app:match(api_route('users/:username'), respond_to({
    POST = UserController.create, -- legacy, used by editor
    DELETE = UserController.delete
}))

-- TODO: Rename this to initialize_password_reset or something
app:match(api_route('users/:username/password_reset'), respond_to({
    POST = UserController.reset_password
}))

app:match(api_route('users/:username/login'), respond_to({
    POST = capture_errors(function(self)
        self.params.password = self.params.body
        return UserController.login(self)
    end)
}))

app:match(api_route('users/:username/set_role'), respond_to({
    POST = UserController.set_role
}))

app:match(api_route('users/:username/set_teacher'), respond_to({
    POST = UserController.set_teacher
}))

app:match(api_route('users/:username/change_email'), respond_to({
    POST = UserController.change_email
}))

app:match(api_route('users/:username/change_username'), respond_to({
    POST = capture_errors(function (self)
        return UserController.change_username(self)
    end)
}))
app:match(api_route('users/:username/send_email'), respond_to({
    POST = UserController.send_email
}))

app:match(api_route('users/:username/become'), respond_to({
    POST = UserController.become
}))

app:match(api_route('users/:username/force_logout'), respond_to({
    POST = UserController.force_logout
}))

app:match(api_route('users/:username/verify'), respond_to({
    POST = UserController.verify
}))

app:match(api_route('users/:username/resendverification'), respond_to({
    POST = UserController.resend_verification
}))

app:match(api_route('users/:username/follow'), respond_to({
    POST = UserController.follow,
    DELETE = UserController.unfollow
}))

app:match(api_route('users/create_learners'), respond_to({
    POST = json_params(UserController.create_learners)
}))

-- Zombies
-- =======

app:match(api_route('zombies/:username'), respond_to({
    DELETE = UserController.perma_delete
}))

app:match(api_route('zombies/:username/revive'), respond_to({
    POST = UserController.revive
}))

-- Emails
-- ======

app:match(api_route('emails/:email/remind_username'), respond_to({
    POST = UserController.remind_username
}))

-- Projects
-- ========
app:match(api_route('projects'), respond_to({
    -- get my projects
    GET = ProjectController.my_projects
}))

app:match(api_route('project/:id/flag'), respond_to({
    POST = ProjectController.flag,
    DELETE = ProjectController.remove_flag
}))

app:match(api_route('project/:id/bookmark/:user_id'), respond_to({
    POST = ProjectController.bookmark,
    DELETE = ProjectController.unbookmark
}))

app:match(api_route('project/:id/mark_as_remix'), respond_to({
    POST = ProjectController.mark_as_remix,
}))

app:match(api_route('project/:id/share'), respond_to({
    POST = ProjectController.share,
    DELETE = ProjectController.unshare
}))

app:match(api_route('project/:id/publish'), respond_to({
    POST = ProjectController.publish,
    DELETE = ProjectController.unpublish
}))

app:match(api_route('project/:id'), respond_to({
    GET = ProjectController.xml,
    DELETE = ProjectController.delete
}))

-- [LEGACY]
-- Legacy API calls by username and projectname. Used by the editor and mods.

app:match(api_route('projects/:username/:projectname'), respond_to({
    GET = ProjectController.xml,
    POST = ProjectController.save,
    DELETE = ProjectController.delete
}))

app:match(api_route('projects/:username/:projectname/thumbnail'), respond_to({
    GET = ProjectController.thumbnail
}))

app:match(api_route('projects/:username'), respond_to({
    GET = ProjectController.user_projects
}))

app:match(api_route('projects/:username/:projectname/metadata'), respond_to({
    POST = ProjectController.metadata
}))

app:match(api_route('projects/:username/:projectname/versions'), respond_to({
    GET = ProjectController.versions
}))

-- [/LEGACY]


-- Collections
-- ===========
app:match(api_route('collections/:username'), respond_to({
    POST = CollectionController.new
}))

app:match(api_route('collection/:id'),
    respond_to({
        DELETE = CollectionController.delete
    })
)

app:match(api_route('collection/:id/name'),
    respond_to({
        POST = CollectionController.rename
    })
)

app:match(api_route('collection/:id/description'),
    respond_to({
        POST = CollectionController.set_description
    })
)

app:match(api_route('collection/:id/editor'),
    respond_to({
        POST = CollectionController.add_editor,
        DELETE = CollectionController.remove_editor
    })
)

app:match(api_route('collection/:id/enrollment'),
    respond_to({
        DELETE = CollectionController.unenroll
    })
)

app:match(api_route('collection/:id/ffa'),
    respond_to({
        POST = CollectionController.make_ffa,
        DELETE = CollectionController.unmake_ffa
    })
)

app:match(api_route('collection/:id/sharing'),
    respond_to({
        POST = CollectionController.share,
        DELETE = CollectionController.unshare
    })
)

app:match(api_route('collection/:id/publishing'),
    respond_to({
        POST = CollectionController.publish,
        DELETE = CollectionController.unpublish
    })
)

app:match(api_route('collection/:id/thumbnail'),
    respond_to({
        POST = CollectionController.set_thumbnail
    })
)

app:match(api_route('collection/:id/project/:project_id'),
    respond_to({
        POST = CollectionController.add_project,
        DELETE = CollectionController.remove_project
    })
)

app:match(api_route('collection/:id/join_token'), respond_to({
    GET = CollectionController.get_join_token,
    POST = CollectionController.get_join_token,
    DELETE = CollectionController.remove_join_token
}))

-- Site
-- ====
app:match(api_route('set_totm'),
    respond_to({
        POST = SiteController.set_totm
    })
)

app:match(api_route('feature_carousel'),
    respond_to({
        POST = SiteController.feature_carousel,
        DELETE = SiteController.unfeature_carousel
    })
)

app:match(api_route('banned_ip/:ip'),
    respond_to({
        DELETE = SiteController.unban_ip
    })
)
