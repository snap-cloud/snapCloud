-- Unified storage dispatcher
-- ==========================
--
-- Wraps the legacy local-disk implementation (`disk.lua`) and an
-- S3-compatible object store (`lib/s3.lua`) behind a single API.
-- Callers should require this module rather than disk.lua directly;
-- `app.lua` continues to expose it as `package.loaded.disk` for
-- backwards compatibility so existing call sites in controllers/*
-- and models/* keep working.
--
-- Storage model
-- -------------
-- Each project has a `storage_location` column ('local' or 's3') that
-- tells us where its authoritative files live. New signups and saves
-- go to S3 when it's configured; projects with `storage_location =
-- 'local'` continue to read from disk until the backfill (or the
-- next successful save) migrates them.
--
-- We deliberately do NOT use a `current/` folder in S3. Moving or
-- copying objects inside S3 to implement versioning adds latency and
-- an extra Class A op per save. Instead, every save writes to a fresh
-- timestamped folder and a single `projects.current_version_key`
-- column on the row points at the live copy. "Backing up" the
-- previous version is then just "don't delete it" plus inserting a
-- `project_versions` row.
--
-- S3 key layout
--   projects/<id>/<version_key>/project.xml
--   projects/<id>/<version_key>/media.xml
--   projects/<id>/<version_key>/thumbnail.png
-- where `<version_key>` is a compact UTC ISO-8601 timestamp,
-- e.g. `20260419T143022123456Z`. Lexicographic sort equals
-- chronological sort, which simplifies "newest first" queries.
--
-- Retention policy (preserves the legacy d-1/d-2 semantics)
-- ---------------------------------------------------------
-- On save we archive the displaced current as a new row in
-- `project_versions`. We then apply two retention rules:
--
--   1. If the previously-archived version was written less than
--      `config.stable_version_age_seconds` (default 12h) before the
--      version we're archiving now, we consider the old archive
--      ephemeral/churn and soft-delete it. This matches the legacy
--      behavior where `d-1` is overwritten on every save.
--
--   2. We cap live (non-deleted) archives at
--      `config.previous_versions_to_keep` (default 2). Anything older
--      is soft-deleted.
--
-- The displaced current is NOT deleted from S3 at this time; a
-- separate janitor (out of scope here) reaps soft-deleted S3 objects
-- after a grace window. Keeping the S3 objects makes the soft-delete
-- reversible if we later raise the retention cap.
--
-- R2 / S3 limits worth knowing
-- ----------------------------
--   * Key length is ≤1024 bytes. Our keys are well under 100.
--   * A bucket can hold effectively unlimited objects, but R2 Class A
--     (writes) is billed per-op beyond the free tier. Each save
--     currently emits 3 PUTs (xml, media, thumbnail) + no copies.
--     Reads are Class B; presigned-URL thumbnail fetches count
--     against that, NOT against the Snap!Cloud server.
--   * R2 LIST is strongly consistent; we still avoid LIST on the hot
--     path and use the DB as the authoritative index of versions.
--   * SigV4 presigned URLs cap at 7 days TTL. We use
--     `config.s3_presign_ttl` (300s default) for thumbnail URLs.
--   * Single-object PUT is capped at 5 GiB; XML/thumbnails are orders
--     of magnitude smaller, so we never need multipart upload.
--   * No "rename" or native "move" op exists — hence the pointer-
--     column design above.
--
-- Written for Snap!Cloud, licensed AGPL.

local disk = require('disk')
local s3 = require('lib.s3')
local encoding = require('lapis.util.encoding')
local socket = require('socket')
local xml = require('xml')

local config = package.loaded.config
local db = package.loaded.db

local storage = {}

-- Precomputed local-to-UTC offset (seconds). `os.time(os.date('!*t',0))`
-- interprets the UTC epoch 0 as if it were local time; the gap tells
-- us how far local is from UTC. We only need this to convert a
-- version_key (which encodes UTC) back to a numeric epoch.
local LOCAL_UTC_OFFSET = os.difftime(os.time(), os.time(os.date('!*t', 0)))

-- S3 enablement ---------------------------------------------------------

local function s3_enabled()
    return s3.is_configured()
end

-- Version keys ---------------------------------------------------------

-- Deterministic UTC format. Microsecond precision gives us headroom
-- against two saves in the same millisecond (unlikely, but we ORDER
-- BY version_key so ties would silently collapse).
local function format_version_key(epoch_float)
    local sec = math.floor(epoch_float)
    local us = math.floor((epoch_float - sec) * 1000000 + 0.5)
    if us >= 1000000 then sec = sec + 1; us = us - 1000000 end
    local d = os.date('!*t', sec)
    return string.format('%04d%02d%02dT%02d%02d%02d%06dZ',
        d.year, d.month, d.day, d.hour, d.min, d.sec, us)
end

local function parse_version_key(key)
    local y, mo, d, h, mi, s, us = (key or ''):match(
        '^(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d)Z$')
    if not y then return nil end
    local utc = os.time({
        year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h), min = tonumber(mi), sec = tonumber(s)
    }) + LOCAL_UTC_OFFSET
    return utc + tonumber(us) / 1000000
end

local function new_version_key()
    return format_version_key(socket.gettime())
end

-- S3 object naming -----------------------------------------------------

-- On disk a thumbnail is a base64 data URL stored in a file named
-- `thumbnail` (no extension). In S3 we store real PNG bytes named
-- `thumbnail.png` so the browser can consume it directly.
local function s3_object_name(filename)
    if filename == 'thumbnail' then return 'thumbnail.png' end
    return filename
end

local function s3_key(id, version_key, filename)
    return 'projects/' .. id .. '/' .. version_key .. '/' ..
        s3_object_name(filename)
end

-- Thumbnail transcoding ------------------------------------------------

-- Strip the `data:image/...;base64,` prefix if present and decode to
-- raw bytes. Some very old projects may have the raw base64 without
-- the data-URL prefix, so we fall through to decoding the whole body.
local function decode_thumbnail(contents)
    if not contents or contents == '' then return nil end
    local payload = contents:match('^data:image/[%w%+%-%.]+;base64,(.+)$')
        or contents:match('^data:image/[%w%+%-%.]+,(.+)$')
        or contents
    local ok, decoded = pcall(encoding.decode_base64, payload)
    if not ok or not decoded or #decoded == 0 then return nil end
    return decoded
end

-- Inverse of decode_thumbnail: pack PNG bytes back into a data URL
-- for JSON responses (e.g. ProjectController.versions) that still
-- expect inline images.
local function encode_thumbnail_dataurl(bytes)
    if not bytes or bytes == '' then return nil end
    local ok, encoded = pcall(encoding.encode_base64, bytes)
    if not ok then return nil end
    return 'data:image/png;base64,' .. encoded
end

-- Project row access ---------------------------------------------------

local function project_row(id)
    return db.select(
        'id, storage_location, current_version_key FROM projects WHERE id = ?',
        id)[1]
end

local function project_is_s3(row)
    return row and row.storage_location == 's3' and row.current_version_key
end

-- Retention ------------------------------------------------------------

-- Insert an archive row for the displaced version and apply the
-- legacy d-1/d-2 retention rule plus the hard cap. Does NOT delete
-- any S3 objects — we soft-delete the DB row and let a separate
-- janitor reap the bytes asynchronously.
local function archive_and_prune(project_id, archived_version_key)
    if not archived_version_key then return end

    local prev_age = parse_version_key(archived_version_key) or 0
    local threshold = config.stable_version_age_seconds or 43200

    -- Find the current most-recent non-deleted archive. If the version
    -- we're archiving was only live for a short time since then, the
    -- newest archive is churn and gets rotated out (legacy d-1
    -- overwrite).
    local newest = db.select([[
        version_key FROM project_versions
        WHERE project_id = ? AND deleted_at IS NULL
        ORDER BY version_key DESC
        LIMIT 1
    ]], project_id)[1]

    if newest then
        local newest_age = parse_version_key(newest.version_key)
        if newest_age and prev_age - newest_age < threshold then
            db.update('project_versions',
                { deleted_at = db.raw('now()'),
                  updated_at = db.raw('now()') },
                { project_id = project_id,
                  version_key = newest.version_key })
        end
    end

    -- Record the archive. ON CONFLICT handles the (unlikely) case
    -- where the same timestamp round-trips — we revive the row
    -- rather than silently failing.
    db.query([[
        INSERT INTO project_versions
            (project_id, version_key, created_at, updated_at)
        VALUES (?, ?, now(), now())
        ON CONFLICT (project_id, version_key) DO UPDATE
            SET deleted_at = NULL, updated_at = now()
    ]], project_id, archived_version_key)

    -- Enforce the hard cap. Anything past the cap is soft-deleted in
    -- oldest-first order.
    local cap = config.previous_versions_to_keep or 2
    local excess = db.select([[
        version_key FROM project_versions
        WHERE project_id = ? AND deleted_at IS NULL
        ORDER BY version_key DESC
        OFFSET ?
    ]], project_id, cap)
    for _, row in ipairs(excess or {}) do
        db.update('project_versions',
            { deleted_at = db.raw('now()'),
              updated_at = db.raw('now()') },
            { project_id = project_id, version_key = row.version_key })
    end
end

-- Upload a (content-typed) file into the versioned S3 folder, applying
-- the thumbnail base64->PNG transform if necessary.
local function upload_file(project_id, version_key, filename, contents)
    local body, ctype = contents, nil
    if filename == 'thumbnail' then
        body = decode_thumbnail(contents)
        ctype = 'image/png'
    elseif filename:match('%.xml$') then
        ctype = 'application/xml'
    end
    if not body then return true end -- nothing to upload, not an error
    local ok, err = s3.put(s3_key(project_id, version_key, filename),
        body, ctype)
    if not ok then
        ngx.log(ngx.ERR, 's3 put failed for project ' .. project_id ..
            ' ' .. filename .. ': ' .. tostring(err))
        return false, err
    end
    return true
end

-- Public API -----------------------------------------------------------

function storage:timestamp_command(dir)
    return disk:timestamp_command(dir)
end

function storage:directory_for_id(id)
    return disk:directory_for_id(id)
end

-- Noop in S3 mode: `save` already archives the displaced version.
-- Kept on the API so existing callers that invoke `disk:backup_project`
-- explicitly (e.g. controllers/project.lua `save`) keep compiling.
-- In disk-only mode we delegate to the legacy implementation so the
-- `d-1`/`d-2` directories continue to be populated during the
-- migration window.
function storage:backup_project(id)
    local row = project_row(id)
    if s3_enabled() and project_is_s3(row) then
        -- Archive-on-save handles this; nothing to do here.
        return
    end
    return disk:backup_project(id)
end

-- Write a single file. A project save calls this three times in a
-- fixed order (see ProjectController.save): project.xml, then
-- thumbnail, then media.xml. We batch all three under a single
-- version_key so they end up in the same folder.
--
-- To correlate those three calls, we treat `project.xml` as the
-- "new save starts here" marker: it always allocates a fresh
-- version_key and archives the previous current. Subsequent
-- non-project.xml calls reuse the current_version_key pointer if
-- they arrive within `SAVE_BATCH_WINDOW` seconds. If the window
-- expires before the secondary files arrive (e.g. a hung request),
-- they get their own version_key — the project_versions retention
-- logic will collapse any resulting near-duplicates on the next
-- save, so we don't accumulate partial-save junk.
local SAVE_BATCH_WINDOW = 30 -- seconds

function storage:save(id, filename, contents)
    if s3_enabled() then
        local row = project_row(id)
        local now = socket.gettime()

        local version_key
        local starting_new_save = false

        if filename == 'project.xml' then
            -- Always begins a fresh logical save.
            version_key = format_version_key(now)
            starting_new_save = true
        else
            -- Reuse the current pointer if it's from the same save,
            -- otherwise start a new one anyway so the file isn't lost.
            local prev_t = row and row.current_version_key
                and parse_version_key(row.current_version_key)
            if prev_t and (now - prev_t) <= SAVE_BATCH_WINDOW
                    and row.storage_location == 's3' then
                version_key = row.current_version_key
            else
                version_key = format_version_key(now)
                starting_new_save = true
            end
        end

        if starting_new_save and project_is_s3(row) then
            archive_and_prune(id, row.current_version_key)
        end

        upload_file(id, version_key, filename, contents)

        if starting_new_save then
            db.update('projects',
                { current_version_key = version_key,
                  storage_location = 's3' },
                { id = id })
        end

        -- Optional safety net during the migration window. Disable
        -- S3_DISK_WRITES once the backfill is complete and reads from
        -- S3 are verified, to stop disk from accumulating new files.
        if config.s3_disk_writes then
            disk:save(id, filename, contents)
        end
        return
    end
    return disk:save(id, filename, contents)
end

-- Read a file. `delta` semantics (from the editor's version picker):
--   nil or 0  → the live current version
--   -1 / -2   → the Nth most-recent non-deleted archived version
--   (any other value is treated as -1)
function storage:retrieve(id, filename, delta)
    local delta_num = delta and tonumber(delta) or 0
    local row = project_row(id)

    if s3_enabled() and project_is_s3(row) then
        local version_key
        if delta_num == 0 then
            version_key = row.current_version_key
        else
            local n = math.max(1, math.abs(delta_num))
            local archives = db.select([[
                version_key FROM project_versions
                WHERE project_id = ? AND deleted_at IS NULL
                ORDER BY version_key DESC
                LIMIT ?
            ]], id, n)
            version_key = archives and archives[n] and archives[n].version_key
        end
        if version_key then
            local body, err = s3.get(s3_key(id, version_key, filename))
            if err then
                ngx.log(ngx.ERR, 's3 get error '
                    .. s3_key(id, version_key, filename) .. ': '
                    .. tostring(err))
            elseif body then
                if filename == 'thumbnail' then
                    return encode_thumbnail_dataurl(body)
                end
                return body
            end
        end
        -- For s3-backed projects we deliberately do NOT fall through
        -- to disk: the disk copy (if any) is stale by definition once
        -- storage_location flipped to 's3'.
        return nil
    end

    -- Local-only path (not yet migrated, or S3 unconfigured).
    return disk:retrieve(id, filename, delta)
end

function storage:retrieve_thumbnail(id)
    return self:retrieve(id, 'thumbnail')
end

function storage:generate_thumbnail(id)
    -- Try to extract the <thumbnail> element from the current project.xml
    -- and stash it as the thumbnail for faster subsequent reads.
    local project_xml = self:retrieve(id, 'project.xml')
    if not project_xml then return nil end
    local thumbnail
    local ok = pcall(function ()
        local parsed = xml.load(project_xml)
        local t = xml.find(parsed, 'thumbnail')
        thumbnail = t and t[1] or nil
    end)
    if not ok or not thumbnail then return false end
    self:save(id, 'thumbnail', thumbnail)
    return thumbnail
end

function storage:parse_notes(id, delta)
    local project_xml = self:retrieve(id, 'project.xml', delta)
    if not project_xml then return '' end
    local notes
    local ok = pcall(function ()
        local parsed = xml.load(project_xml)
        local n = xml.find(parsed, 'notes')
        notes = n and n[1] or nil
    end)
    if not ok then return '' end
    return notes or ''
end

function storage:update_notes(id, notes)
    return self:update_xml(id, function (project)
        local old_notes = xml.find(project, 'notes')
        old_notes[1] = notes
    end)
end

function storage:update_name(id, name)
    return self:update_xml(id, function (project)
        project.name = name
    end)
end

function storage:update_metadata(id, name, notes)
    return self:update_xml(id, function (project)
        project.name = name
        local old_notes = xml.find(project, 'notes')
        old_notes[1] = notes
    end)
end

function storage:update_xml(id, update_function)
    local project_xml = self:retrieve(id, 'project.xml')
    if not project_xml then
        package.loaded.yield_error(err.file_not_found)
    end
    local success, message = pcall(function ()
        local parsed = xml.load(project_xml)
        update_function(parsed)
        -- storage:save handles archive-on-save for s3 projects; for
        -- disk-only projects the legacy disk:save path still calls
        -- backup_project separately, so we invoke it here to match.
        local row = project_row(id)
        if not (s3_enabled() and project_is_s3(row)) then
            disk:backup_project(id)
        end
        self:save(id, 'project.xml', xml.dump(parsed))
    end)
    if not success then
        ngx.log(ngx.ERR, 'update_xml failed: ' .. tostring(message))
        package.loaded.yield_error(
            err.unparseable_xml .. tostring(message))
    end
end

-- Return the metadata for the Nth most-recent archived version.
-- Used by ProjectController.versions to render the "revert" picker.
function storage:get_version_metadata(id, delta)
    local delta_num = tonumber(delta) or -1
    local row = project_row(id)

    if s3_enabled() and project_is_s3(row) then
        local n = math.max(1, math.abs(delta_num))
        local archives = db.select([[
            version_key, extract(epoch from created_at) AS ts
            FROM project_versions
            WHERE project_id = ? AND deleted_at IS NULL
            ORDER BY version_key DESC
            LIMIT ?
        ]], id, n)
        local target = archives and archives[n]
        if not target then return nil end

        local thumb_bytes = s3.get(
            s3_key(id, target.version_key, 'thumbnail'))
        return {
            notes = self:parse_notes(id, delta_num),
            thumbnail = encode_thumbnail_dataurl(thumb_bytes),
            lastupdated = os.time() - tonumber(target.ts),
            delta = delta_num,
        }
    end
    return disk:get_version_metadata(id, delta_num)
end

function storage:process_notes(projects)
    for _, project in pairs(projects) do
        if project.notes == nil then
            local notes = self:parse_notes(project.id)
            if notes then
                project:update({ notes = notes })
                project.notes = notes
            end
        end
    end
end

-- In S3 mode, point <img src> at the image endpoint. It 302s to a
-- short-lived presigned URL so browsers fetch the PNG directly from
-- R2 rather than having Snap!Cloud proxy every byte.
function storage:process_thumbnails(items, id_selector)
    local key = id_selector or 'id'
    if s3_enabled() then
        for _, item in pairs(items) do
            local id = item[key]
            if id then
                item.thumbnail = storage:thumbnail_url(id)
            end
        end
        return
    end
    for _, item in pairs(items) do
        local id = item[key]
        if id then
            item.thumbnail =
                disk:retrieve(id, 'thumbnail') or
                disk:generate_thumbnail(id)
        end
    end
end

function storage:thumbnail_url(id)
    return '/api/v1/project/' .. tostring(id) .. '/image.png'
end

-- Generate a short-lived presigned URL for the project's thumbnail.
-- Callers MUST perform the permission check BEFORE invoking this.
-- Returns nil when the project isn't stored in S3 or the object is
-- missing.
function storage:presigned_thumbnail_url(id, version_delta)
    if not s3_enabled() then return nil end
    local row = project_row(id)
    if not project_is_s3(row) then return nil end

    local version_key = row.current_version_key
    local delta_num = version_delta and tonumber(version_delta) or 0
    if delta_num ~= 0 then
        local n = math.max(1, math.abs(delta_num))
        local archives = db.select([[
            version_key FROM project_versions
            WHERE project_id = ? AND deleted_at IS NULL
            ORDER BY version_key DESC
            LIMIT ?
        ]], id, n)
        version_key = archives and archives[n]
            and archives[n].version_key
        if not version_key then return nil end
    end

    local key = s3_key(id, version_key, 'thumbnail')
    if not s3.exists(key) then return nil end
    return s3.presign_get(key,
        (config.s3_presign_ttl or 300), 'image/png')
end

-- Serve raw PNG bytes from the project's thumbnail. Only used when
-- S3 is not configured (disk-only dev) or when the S3 fetch failed
-- and we want to fall back to materializing from project.xml.
function storage:read_thumbnail_bytes(id, version_delta)
    local row = project_row(id)
    if s3_enabled() and project_is_s3(row) then
        local version_key = row.current_version_key
        local delta_num = version_delta and tonumber(version_delta) or 0
        if delta_num ~= 0 then
            local n = math.max(1, math.abs(delta_num))
            local archives = db.select([[
                version_key FROM project_versions
                WHERE project_id = ? AND deleted_at IS NULL
                ORDER BY version_key DESC
                LIMIT ?
            ]], id, n)
            version_key = archives and archives[n]
                and archives[n].version_key
            if not version_key then return nil end
        end
        return s3.get(s3_key(id, version_key, 'thumbnail'))
    end
    local contents = disk:retrieve(id, 'thumbnail', version_delta)
    return contents and decode_thumbnail(contents) or nil
end

function storage:delete_project(id)
    -- Best-effort hard delete of object storage for this project.
    local row = project_row(id)
    if s3_enabled() and project_is_s3(row) then
        if row.current_version_key then
            for _, fname in ipairs(
                    { 'project.xml', 'media.xml', 'thumbnail' }) do
                pcall(function ()
                    s3.delete(s3_key(id, row.current_version_key, fname))
                end)
            end
        end
        local archives = db.select([[
            version_key FROM project_versions WHERE project_id = ?
        ]], id)
        for _, r in ipairs(archives or {}) do
            for _, fname in ipairs(
                    { 'project.xml', 'media.xml', 'thumbnail' }) do
                pcall(function ()
                    s3.delete(s3_key(id, r.version_key, fname))
                end)
            end
        end
        db.delete('project_versions', 'project_id = ?', id)
    end
end

function storage:save_totm_banner(file)
    return disk:save_totm_banner(file)
end

-- Exports --------------------------------------------------------------

storage.s3_enabled = s3_enabled
storage.s3_key = s3_key
storage.s3_object_name = s3_object_name
storage.format_version_key = format_version_key
storage.parse_version_key = parse_version_key
storage.new_version_key = new_version_key
storage.decode_thumbnail = decode_thumbnail
storage.encode_thumbnail_dataurl = encode_thumbnail_dataurl
-- Raw disk backend so callers that want to bypass hybrid dispatch
-- (e.g. the backfill) can read files directly from local disk.
storage.disk_backend = disk
-- Public retention constants. Exported so the backfill can mirror
-- the same policy when seeding `project_versions` from legacy
-- `d-1`/`d-2` directories.
storage.PREVIOUS_VERSIONS_TO_KEEP = config.previous_versions_to_keep or 2
storage.STABLE_VERSION_AGE_SECONDS =
    config.stable_version_age_seconds or 43200

return storage
