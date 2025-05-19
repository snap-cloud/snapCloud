-- Database abstractions
-- =====================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

package.loaded.Model = require('lapis.db.model').Model

-- TODO: This does not actually autoload the models
-- In the meantime, we will require them manually
-- return require("lapis.util").autoload("models")

package.loaded.BannedIPs = require("models.banned_ips")
package.loaded.CollectionMemberships = require("models.collection_memberships")
package.loaded.Collections = require("models.collections" )
package.loaded.FeaturedCollections = require("models.featured_collections")
package.loaded.FlaggedProjects = require("models.flagged_projects")
package.loaded.Followers = require("models.followers" )
package.loaded.Bookmarks = require("models.bookmarks" )
package.loaded.Projects = require("models.projects")
package.loaded.Remixes = require("models.remixes" )
package.loaded.Tokens = require("models.tokes" )
package.loaded.Users = require("models.users" )
