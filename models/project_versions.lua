-- Snap!Cloud ProjectVersions Model
-- ================================
--
-- Tracks historical versions of a project's files in S3/R2. Each row
-- describes one retired version; the live current version is recorded
-- on `projects.current_version_key` and NOT in this table.
--
-- `version_key` is the S3 path segment (e.g. `20260419T143022123456Z`)
-- that points at `projects/<project_id>/<version_key>/{project.xml,
-- media.xml, thumbnail.png}`. Sorting by `version_key` DESC is
-- equivalent to chronological DESC because the format is zero-padded
-- UTC ISO 8601.
--
-- `deleted_at` is the soft-delete tombstone: storage.lua's retention
-- logic sets it when a version is evicted, but leaves the row so we
-- can revive it if we later decide to bump PREVIOUS_VERSIONS_TO_KEEP.
-- `updated_at` records the last time a retention pass touched the row.
--
-- A cloud backend for Snap!
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

local Model = package.loaded.Model

local ProjectVersions = Model:extend('project_versions', {
    primary_key = { 'project_id', 'version_key' }
})

return ProjectVersions
