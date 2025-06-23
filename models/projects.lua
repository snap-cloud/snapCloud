-- Snap!Cloud Projects Model
-- =========================
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

local db = package.loaded.db
local Model = package.loaded.Model

local escape = require('lapis.util').escape
local disk = package.loaded.disk

-- Generated schema dump: (do not edit)
--
-- CREATE VIEW active_projects AS
--  SELECT projects.id,
--   projects.projectname,
--   projects.ispublic,
--   projects.ispublished,
--   projects.notes,
--   projects.created,
--   projects.lastupdated,
--   projects.lastshared,
--   projects.username,
--   projects.firstpublished,
--   projects.deleted
--    FROM public.projects
--   WHERE (projects.deleted IS NULL);
--
local ActiveProjects = Model:extend('active_projects', {
    type = 'project',
    primary_key = {'username', 'projectname'},
    constraints = {
        projectname = function (_self, name)
            -- TODO: Use a whitespace stripping + normalization function
            if not name or string.len(name) < 1 then
                return "Project names must have at least one character."
            end
        end
    },
    recently_bookmarked = function ()
        -- This query was gerneted by Claude, insprite by the Hacker News
        -- algorithm for ranking projects based on recent bookmarks.
        -- We rank projects based on the number of bookmarks in last 30 days,
        -- giving more weight to recent bookmarks.
        -- 86400 is the number of seconds in a day
        -- * 5 boosts the score of based on the recency of the last update of the project
        local rows = db.query([[
            WITH recent_bookmark_activity AS (
                SELECT
                    project_id,
                    COUNT(*) as recent_bookmarks,
                    SUM(
                        CASE
                            WHEN created_at > NOW() - INTERVAL '1 day' THEN 10
                            WHEN created_at > NOW() - INTERVAL '3 days' THEN 5
                            WHEN created_at > NOW() - INTERVAL '7 days' THEN 2
                            ELSE 0
                        END
                    ) as weighted_recent_score
                FROM bookmarks
                WHERE created_at > NOW() - INTERVAL '30 days'
                GROUP BY project_id
            )
            SELECT p.id,
                COALESCE(r.recent_bookmarks, 0) as recent_bookmarks,
                COALESCE(r.weighted_recent_score, 0) as bookmark_score,
                (COALESCE(r.weighted_recent_score, 0) +
                GREATEST(0, 1 - EXTRACT(EPOCH FROM (NOW() - p.lastupdated)) / (86400 * 30)) * 5) as final_score
            FROM recent_bookmark_activity r
            JOIN active_projects p ON p.id = r.project_id
            WHERE p.ispublic AND p.ispublished
            ORDER BY final_score DESC
            LIMIT 240
        ]])

        local result = {}
        for i, item in ipairs(rows) do
            local project = package.loaded.Projects:find({ id = item.id})
            if project then
                project.recent_bookmarks = item.recent_bookmarks
                project.final_score = item.final_score
                result[i] = project
            end
        end
        disk:process_thumbnails(result)
        return result
    end,
    url_for = function (self, purpose, dev_version)
        -- For some small % of requests the host is nil.
        local domain = ngx.var.http_host or 'snap.berkeley.edu'
        local base = ngx and ngx.var and ngx.var.scheme .. '://' .. domain .. '/' or ''
        base = base .. (dev_version and 'snap/dev/' or 'snap/') .. 'snap.html'
        local urls = {
            viewer = base ..
                '#present:Username=' .. escape(self.username) ..
                '&ProjectName=' .. escape(self.projectname) ..
                '&embedMode&noExitWarning&noRun',
            open = base ..
                '#present:Username=' .. escape(self.username) ..
                '&ProjectName=' .. escape(self.projectname) ..
                '&editMode&noRun',
            download = '/project/' .. escape(self.id),
            site = '/project?username=' .. escape(self.username) ..
                '&projectname=' .. escape(self.projectname),
            author = '/user?username=' .. escape(self.username),
            embed = 'https://snap.berkeley.edu/embed?projectname=' ..
                escape(self.projectname) .. '&username=' ..
                escape(self.username)
        }
        return urls[purpose]
    end,
    bookmarked_by = function (self, bookmarker)
      return package.loaded.Bookmarks:find({
        bookmarker_id = bookmarker.id,
        project_id = self.id
      }) ~= nil
    end,
    relations = {
        {'flags',
            fetch = function (self)
                return package.loaded.FlaggedProjects:select(
                    'JOIN active_users ON active_users.id = flagger_id '..
                    'WHERE project_id = ? ' ..
                    'GROUP BY reason, username, created_at, notes',
                    self.id,
                    { fields = 'username, created_at, reason, notes' }
                )
            end
        },
        {'bookmark_count',
            fetch = function (self)
                return package.loaded.Bookmarks:select(
                    'WHERE project_id = ?',
                    self.id,
                    { fields = 'count(*) as count' }
                )[1].count
            end
        },
        {'public_remixes',
            fetch = function (self)
                local items = package.loaded.Projects:select(
                   [[JOIN remixes
                        ON active_projects.id = remixes.remixed_project_id
                    WHERE remixes.original_project_id = ?
                    AND ispublic]],
                    self.id
                )
                disk:process_thumbnails(items)
                return items
            end
        },
        {'public_collections',
            fetch = function (self)
                local items = package.loaded.Collections:select(
                    [[INNER JOIN collection_memberships
                        ON collection_memberships.collection_id = collections.id
                    INNER JOIN users
                        ON collections.creator_id = users.id
                    WHERE collection_memberships.project_id = ?
                    AND collections.published]],
                    self.id
                )
                disk:process_thumbnails(items, 'thumbnail_id')
                return items
            end
        },
    }
})

package.loaded.DeletedProjects = Model:extend('deleted_projects', {
    primary_key = {'username', 'projectname'}
})

return ActiveProjects
