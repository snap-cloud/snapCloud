-- LTI 1.3 tool routes
-- ===================
--
-- Wires up the LTI 1.3 endpoints and the teacher-facing registration UI.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2026 by Bernat Romagosa and Michael Ball
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

local app = package.loaded.app
local respond_to = package.loaded.respond_to

require 'controllers.lti'

-- Public endpoints for the LMS ------------------------------------------

-- OIDC login initiation. Platforms may call with either GET or POST per the
-- IMS Security Framework.
app:match('/lti/login', respond_to({
    GET = LtiController.login_initiation,
    POST = LtiController.login_initiation
}))

-- Launch callback. Platforms always post the id_token here, but accepting
-- GET makes local debugging easier.
app:match('/lti/launch', respond_to({
    GET = LtiController.launch,
    POST = LtiController.launch
}))

-- Tool JWKS. Intentionally cacheable since key rotation is explicit.
app:match('/lti/jwks', respond_to({
    GET = LtiController.jwks
}))

-- Teacher-facing registration UI / API ---------------------------------

app:match('lti_config', '/lti/config', respond_to({
    GET = LtiController.config_page
}))

app:match('/lti/platforms', respond_to({
    POST = LtiController.create_platform
}))

app:match('/lti/platforms/:id', respond_to({
    DELETE = LtiController.delete_platform
}))
