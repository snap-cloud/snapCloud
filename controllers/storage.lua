-- Storage migration controller
-- ============================
--
-- Bearer-token-authenticated endpoints for backfilling local-disk
-- project files into the S3-compatible object store. Designed to be
-- invoked iteratively from cron or a shell loop so the migration can
-- run slowly without blocking user traffic.
--
-- Auth
-- ----
-- These endpoints are NOT behind the user session. They require the
-- `X-Migration-Token` header (or `?token=...`) to match
-- `config.storage_migration_token`, which is set from the
-- `STORAGE_MIGRATION_TOKEN` env var. When the env var is unset the
-- endpoints return 503, so a misconfigured box can't be tricked into
-- backfilling with an empty token. The admin-cookie approach was
-- dropped because a long-running shell loop around a session cookie
-- is operationally brittle (sessions expire, cookies rotate).
--
-- Typical invocation:
--
--     while true; do
--       curl -fsS -X POST \
--         -H "X-Migration-Token: $MIGRATION_TOKEN" \
--         "$HOST/api/v1/admin/storage/migrate?batch=100"
--       sleep 2
--     done
--
-- Each call migrates a bounded batch of projects, reports what it
-- touched, and exits. `projects.storage_location` tracks progress so
-- re-runs skip already-migrated rows.
--
-- Written for Snap!Cloud, licensed AGPL.

local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local db = package.loaded.db
local config = package.loaded.config
local storage = package.loaded.storage
local s3 = require('lib.s3')

-- Grab the raw disk backend through storage so reads in this
-- controller bypass the hybrid dispatch. Once a project's row flips
-- to storage_location='s3' the hybrid reader will no longer serve
-- from disk, but the files are still there and we need them for the
-- upload step.
local disk = storage.disk_backend

-- Auth -----------------------------------------------------------------

local function check_migration_token(self)
    local expected = config.storage_migration_token
    if not expected or expected == '' then
        yield_error({
            msg = 'Storage migration endpoint is disabled. ' ..
                'Set STORAGE_MIGRATION_TOKEN to enable it.',
            status = 503
        })
    end
    local headers = ngx.req.get_headers()
    local provided = headers['x-migration-token']
        or headers['X-Migration-Token']
        or self.params.token
    if provided ~= expected then
        yield_error({ msg = 'Invalid migration token.', status = 403 })
    end
end

-- Backfill primitives --------------------------------------------------

-- Return the mtime (epoch seconds, integer) of a disk file, or nil.
-- Uses the same stat invocation as disk.lua so we see the same
-- timestamps the live site does.
local function file_mtime(path)
    local cmd = io.popen('stat ' .. config.stat_arguments .. ' ' .. path
        .. ' 2>/dev/null')
    if not cmd then return nil end
    local raw = cmd:read('*a')
    cmd:close()
    return tonumber(raw)
end

-- Upload one logical file (project.xml, media.xml, thumbnail) from
-- disk to S3 under the given version_key. Handles the thumbnail
-- base64->PNG transform. Returns (ok, err).
local function upload_disk_file(id, version_key, fname, delta)
    local body = disk:retrieve(id, fname, delta)
    if not body then return true end
    local key = storage.s3_key(id, version_key, fname)
    local ctype = 'application/xml'
    if fname == 'thumbnail' then
        body = storage.decode_thumbnail(body)
        ctype = 'image/png'
        if not body then return true end
    end
    local ok, err = s3.put(key, body, ctype)
    if not ok then
        return nil, 'put ' .. key .. ' failed: ' .. tostring(err)
    end
    return true
end

-- Migrate a single project from disk to S3. Idempotent-ish: if the
-- project is already marked 's3' we skip. Existing S3 keys are
-- overwritten (PUT), so partially-failed runs are safe to retry.
local function migrate_one(project)
    local id = project.id
    local dir = disk:directory_for_id(id)
    local migrated = { current = 0, versions = 0 }

    if project.storage_location == 's3' then
        return migrated
    end

    local current_xml_path = dir .. '/project.xml'
    local current_f = io.open(current_xml_path, 'r')
    if not current_f then
        -- Nothing on disk for this row. Leave as 'local' so a fresh
        -- save goes through the normal path.
        return migrated
    end
    current_f:close()

    local current_mt = file_mtime(current_xml_path) or os.time()

    -- Walk the historical deltas oldest-first so their version_keys
    -- sort before the current key. d-2 is the older one (12h+ stable
    -- snapshot); d-1 is the more recent.
    local used_keys = {}
    local archive_plan = {}
    for _, delta in ipairs({ -2, -1 }) do
        local delta_xml = dir .. '/d' .. delta .. '/project.xml'
        if io.open(delta_xml, 'r') then
            local mt = file_mtime(delta_xml) or (current_mt - 1)
            -- Ensure the derived key is strictly earlier than the
            -- current key, and unique within this project.
            local epoch = mt + 0.0
            if epoch >= current_mt then epoch = current_mt - 1 end
            local vkey = storage.format_version_key(epoch)
            while used_keys[vkey] do
                epoch = epoch - 0.000001
                vkey = storage.format_version_key(epoch)
            end
            used_keys[vkey] = true
            table.insert(archive_plan, { delta = delta, version_key = vkey })
        end
    end

    -- Upload archive versions and seed project_versions rows.
    for _, step in ipairs(archive_plan) do
        for _, fname in ipairs(
                { 'project.xml', 'media.xml', 'thumbnail' }) do
            local ok, err = upload_disk_file(
                id, step.version_key, fname, step.delta)
            if not ok then return nil, err end
        end
        db.query([[
            INSERT INTO project_versions
                (project_id, version_key, created_at, updated_at)
            VALUES (?, ?, now()::timestamp, now()::timestamp)
            ON CONFLICT (project_id, version_key) DO NOTHING
        ]], id, step.version_key)
        migrated.versions = migrated.versions + 1
    end

    -- Upload the current version.
    local current_vkey = storage.format_version_key(current_mt)
    -- Guard against collisions with historical keys (same mtime-second
    -- as one of the deltas). Extremely unlikely but cheap to enforce.
    while used_keys[current_vkey] do
        current_mt = current_mt + 1
        current_vkey = storage.format_version_key(current_mt)
    end
    for _, fname in ipairs({ 'project.xml', 'media.xml', 'thumbnail' }) do
        local ok, err = upload_disk_file(id, current_vkey, fname, nil)
        if not ok then return nil, err end
        migrated.current = migrated.current + 1
    end

    -- Flip the pointer. Order matters: if we set storage_location='s3'
    -- before the upload completed, reads would 404.
    db.update('projects',
        { storage_location = 's3',
          current_version_key = current_vkey },
        { id = id })

    return migrated
end

-- Controller -----------------------------------------------------------

StorageController = {
    migrate = capture_errors(function (self)
        check_migration_token(self)
        if not s3.is_configured() then
            return errorResponse(self,
                'Object storage is not configured on this server.', 400)
        end

        local batch = tonumber(self.params.batch) or 50
        if batch > 500 then batch = 500 end

        -- Pick projects that still live on local disk. The query
        -- treats a null value the same as 'local' so we pick up rows
        -- created before the migration ran.
        local rows = db.select([[
            id, storage_location FROM projects
            WHERE coalesce(storage_location, 'local') = 'local'
              AND deleted IS NULL
            ORDER BY id ASC
            LIMIT ?
        ]], batch)

        local report = {
            scanned = 0, migrated = 0, skipped = 0,
            uploaded_current = 0, uploaded_versions = 0, errors = {}
        }
        for _, row in ipairs(rows) do
            report.scanned = report.scanned + 1
            local ok, result_or_err = pcall(migrate_one, row)
            if ok and type(result_or_err) == 'table' then
                if result_or_err.current > 0 or result_or_err.versions > 0
                then
                    report.migrated = report.migrated + 1
                else
                    report.skipped = report.skipped + 1
                end
                report.uploaded_current =
                    report.uploaded_current + result_or_err.current
                report.uploaded_versions =
                    report.uploaded_versions + result_or_err.versions
            else
                table.insert(report.errors,
                    { id = row.id, error = tostring(result_or_err) })
            end
        end

        report.done = #rows < batch
        return jsonResponse(report)
    end),

    status = capture_errors(function (self)
        check_migration_token(self)
        local total = db.select(
            'count(*) FROM projects WHERE deleted IS NULL')[1].count
        local migrated = db.select([[
            count(*) FROM projects
            WHERE deleted IS NULL AND storage_location = 's3'
        ]])[1].count
        local archived = db.select([[
            count(*) FROM project_versions WHERE deleted_at IS NULL
        ]])[1].count
        return jsonResponse({
            s3_configured = s3.is_configured(),
            s3_disk_writes = config.s3_disk_writes or false,
            total_projects = tonumber(total),
            migrated_projects = tonumber(migrated),
            remaining = tonumber(total) - tonumber(migrated),
            archived_versions = tonumber(archived),
            previous_versions_to_keep = storage.PREVIOUS_VERSIONS_TO_KEEP,
            stable_version_age_seconds = storage.STABLE_VERSION_AGE_SECONDS,
        })
    end),
}

return StorageController
