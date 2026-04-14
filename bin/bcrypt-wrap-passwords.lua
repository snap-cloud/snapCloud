-- Bulk bcrypt-wrap migration for existing SHA-512 passwords
-- =========================================================
--
-- This script wraps every legacy SHA-512 password hash with bcrypt, upgrading
-- users from password_version 0 to password_version 1.  This is a one-time
-- bulk operation that should be run AFTER deploying the migration that adds
-- the password_version column.
--
-- After this script completes, every user's password is protected by bcrypt
-- even if the database is leaked.  Users are then silently upgraded to
-- password_version 2 (native bcrypt) on their next successful login.
--
-- Usage:
--     cd snapCloud
--     lapis exec - < bin/bcrypt-wrap-passwords.lua
--
-- The script processes users in batches of 100 and prints progress to stdout.
-- It is safe to re-run: it only touches users still on password_version 0.
--
-- Estimated runtime: ~1 second per user at cost 12 on modern hardware.
-- For 10,000 users expect ~3 hours. Plan accordingly and run in a screen/tmux.
--
-- Copyright (C) 2026 by Bernat Romagosa and Michael Ball
-- License: AGPL-3.0 (same as snapCloud)

local db = require("lapis.db")
local bcrypt = require("bcrypt")

local BCRYPT_LOG_ROUNDS = 12
local BATCH_SIZE = 100

-- Counters
local total_upgraded = 0
local total_skipped = 0
local total_errors = 0

print("=== bcrypt password wrapping migration ===")
print("Cost factor: " .. BCRYPT_LOG_ROUNDS)
print("Batch size:  " .. BATCH_SIZE)
print("")

-- Count how many users need migration
local count_result = db.query(
    "SELECT count(*) AS cnt FROM users WHERE password_version = 0"
)
local total_to_migrate = tonumber(count_result[1].cnt)
print("Users to migrate: " .. total_to_migrate)

if total_to_migrate == 0 then
    print("Nothing to do. All users are already on password_version >= 1.")
    return
end

print("Starting migration...")
print("")

-- Process in batches, ordered by id so we make steady forward progress.
-- We re-query each batch because we update password_version as we go,
-- so the WHERE clause naturally advances.
while true do
    local users = db.query(
        "SELECT id, username, password, salt FROM users " ..
        "WHERE password_version = 0 " ..
        "ORDER BY id ASC LIMIT ?",
        BATCH_SIZE
    )

    if not users or #users == 0 then
        break
    end

    for _, user in ipairs(users) do
        -- Guard: skip users whose password is already a bcrypt hash
        -- (shouldn't happen, but be safe).
        if user.password and user.password:sub(1, 4) == "$2b$" then
            total_skipped = total_skipped + 1
        else
            local ok, new_hash = pcall(bcrypt.digest, user.password, BCRYPT_LOG_ROUNDS)
            if ok then
                local update_ok, update_err = pcall(function()
                    db.update("users", {
                        password = new_hash,
                        password_version = 1
                    }, { id = user.id })
                end)
                if update_ok then
                    total_upgraded = total_upgraded + 1
                else
                    print("  ERROR updating user " .. user.username ..
                          " (id=" .. user.id .. "): " .. tostring(update_err))
                    total_errors = total_errors + 1
                end
            else
                print("  ERROR hashing user " .. user.username ..
                      " (id=" .. user.id .. "): " .. tostring(new_hash))
                total_errors = total_errors + 1
            end
        end
    end

    print("  progress: " .. total_upgraded .. " / " .. total_to_migrate ..
          " upgraded (" .. total_errors .. " errors, " ..
          total_skipped .. " skipped)")
end

print("")
print("=== Migration complete ===")
print("  Upgraded: " .. total_upgraded)
print("  Skipped:  " .. total_skipped)
print("  Errors:   " .. total_errors)

if total_errors > 0 then
    print("")
    print("WARNING: " .. total_errors .. " users could not be migrated.")
    print("Re-run this script to retry, or investigate the errors above.")
end
