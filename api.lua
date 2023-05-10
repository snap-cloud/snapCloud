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
local yield_error = package.loaded.yield_error
local json_params = package.loaded.json_params
local respond_to = package.loaded.respond_to

require 'validation'

require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'
require 'controllers.site'

-- All API routes are nested under /api/v1,
-- which is currently an optional prefix.
local function api_route(path) return '/(api/' .. api_version .. '/)' .. path end

-- API Endpoints
-- =============
app:match(api_route('version'), respond_to({
    GET = capture_errors(function (self)
        return jsonResponse({
            name = 'Snap! Cloud',
            version = api_version
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
        return errorResponse(
            'It seems like you are trying to log in. ' ..
            'Try refreshing the page and try again. ' ..
            'This URL is internal to the Snap!Cloud.',
            400)
    end),
    POST = capture_errors(function (self)
        if not self.session.username or
            (self.session.username and
                self.cookies.persist_session == 'false') then
            self.session.username = ''
        end
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
    GET = UserController.logout,
    POST = UserController.logout
}))

app:match(api_route('unbecome'), respond_to({
    POST = UserController.unbecome
}))

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

app:match(api_route('users/:username/make_teacher'), respond_to({
    POST = UserController.make_teacher
}))

app:match(api_route('users/:username/change_email'), respond_to({
    POST = UserController.change_email
}))

app:match(api_route('users/:username/send_email'), respond_to({
    POST = UserController.send_email
}))

app:match(api_route('users/:username/become'), respond_to({
    POST = UserController.become
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
