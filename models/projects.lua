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
    -- SQL fragment for public project listings (explore, search). Projects
    -- by student and banned users are hidden from everyone below reviewer;
    -- reviewers and above see all of them.
    public_visibility_clause = function (_self, viewer)
        if viewer and viewer:has_min_role('reviewer') then
            return ''
        end
        return [[ AND NOT EXISTS(
                SELECT 1 FROM users WHERE
                username = active_projects.username
                AND role IN ('student', 'banned') LIMIT 1)]]
    end,
    -- Trash every live project of a user, stamped with the given time so
    -- restore_for_user can bring back exactly this set later (projects the
    -- user had trashed before keep their own timestamp). Used when an
    -- account is deleted: every listing then excludes the projects through
    -- active_projects (deleted IS NULL) instead of an anti-join against
    -- deleted_users per query.
    trash_for_user = function (_self, username, deleted_at)
        db.query(
            'UPDATE projects SET deleted = ? ' ..
                'WHERE username = ? AND deleted IS NULL',
            deleted_at, username
        )
        package.loaded.uncache_category('latest')
        package.loaded.uncache_category('latest#count')
    end,
    -- The inverse of trash_for_user: only projects trashed at that exact
    -- time come back.
    restore_for_user = function (_self, username, deleted_at)
        db.query(
            'UPDATE projects SET deleted = NULL ' ..
                'WHERE username = ? AND deleted = ?',
            username, deleted_at
        )
        package.loaded.uncache_category('latest')
        package.loaded.uncache_category('latest#count')
    end,
    -- Class work (likely_class_work) hides a project from Explore. It is
    -- set from heuristics (student accounts, course-like names), inherited
    -- by remixes, and set by reviewers; once set it is only ever cleared by
    -- a reviewer, never by a plain save.

    -- True when the project with that id exists and is flagged as class
    -- work; false for nil (no remix original) or an unknown id.
    is_class_work = function (_self, project_id)
        if not project_id then return false end
        local project = package.loaded.Projects:find({ id = project_id })
        return (project and project.likely_class_work) and true or false
    end,
    -- Sets the class-work flag on a project and every (transitive) remix
    -- of it, so that marking and unmarking are exact inverses. Walks the
    -- whole remix tree; UNION stops it on remix cycles. Rows that already
    -- carry the wanted value are left alone, so repeating a mark is cheap.
    set_class_work_tree = function (_self, project_id, flag)
        db.query([[
            WITH RECURSIVE descendants AS (
                SELECT ?::integer AS id
                UNION
                SELECT remixes.remixed_project_id
                FROM remixes
                INNER JOIN descendants
                    ON descendants.id = remixes.original_project_id
            )
            UPDATE projects SET likely_class_work = ?
            WHERE id IN (SELECT id FROM descendants)
                AND likely_class_work IS DISTINCT FROM ?
        ]], project_id, flag, flag)
        package.loaded.uncache_category('latest')
        package.loaded.uncache_category('latest#count')
    end,
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
            download = '/api/v1/project/' .. escape(self.id),
            site = '/users/' .. escape(self.username) ..
                '/projects/' .. escape(self.projectname),
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
    -- Public remixes, newest first; nil limit = all. Returns items + total
    -- count (a window column, so the total rides along with the capped rows).
    public_remixes = function (self, limit)
        local items = package.loaded.Projects:select(
            [[JOIN remixes
                ON active_projects.id = remixes.remixed_project_id
            WHERE remixes.original_project_id = ?
            AND ispublic
            ORDER BY remixes.created DESC NULLS LAST]] ..
            (limit and ('\nLIMIT ' .. tonumber(limit)) or ''),
            self.id,
            { fields = '*, count(*) OVER () AS total_count' }
        )
        disk:process_thumbnails(items)
        return items, (items[1] and tonumber(items[1].total_count) or 0)
    end,
    -- Published collections containing this project, newest first; same contract.
    public_collections = function (self, limit)
        local items = package.loaded.Collections:select(
            [[INNER JOIN collection_memberships
                ON collection_memberships.collection_id = collections.id
            INNER JOIN users
                ON collections.creator_id = users.id
            WHERE collection_memberships.project_id = ?
            AND collections.published
            ORDER BY collections.published_at DESC NULLS LAST]] ..
            (limit and ('\nLIMIT ' .. tonumber(limit)) or ''),
            self.id,
            { fields = '*, count(*) OVER () AS total_count' }
        )
        disk:process_thumbnails(items, 'thumbnail_id')
        return items, (items[1] and tonumber(items[1].total_count) or 0)
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
    }
})

package.loaded.DeletedProjects = Model:extend('deleted_projects', {
    primary_key = {'username', 'projectname'}
})

return ActiveProjects
