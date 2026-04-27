#!/usr/bin/env lua
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
--     source .env
--     lua bin/bcrypt-wrap-passwords.lua
--
-- The script connects directly to PostgreSQL using pgmoon (no lapis server
-- needed).  It reads database credentials from the same environment variables
-- as config.lua.
--
-- It processes users in batches of 100 and prints progress to stdout.
-- It is safe to re-run: it only touches users still on password_version 0.
--
-- Estimated runtime: ~0.1s per user at cost 12 on modern hardware.
-- For 10,000 users expect ~15-20 minutes. Plan accordingly and run in
-- a screen/tmux session.
--
-- Copyright (C) 2026 by Bernat Romagosa and Michael Ball
-- License: AGPL-3.0 (same as snapCloud)

local pgmoon = require("pgmoon")
local bcrypt = require("bcrypt")

-- ── Configuration ──────────────────────────────────────────────────────────
local BCRYPT_LOG_ROUNDS = 12
local BATCH_SIZE = 100

local db_host     = os.getenv("DATABASE_HOST")     or "127.0.0.1"
local db_port     = os.getenv("DATABASE_PORT")      or "5432"
local db_user     = os.getenv("DATABASE_USERNAME")  or "cloud"
local db_password = os.getenv("DATABASE_PASSWORD")  or "snap-cloud-password"
local db_name     = os.getenv("DATABASE_NAME")      or "snapcloud"

-- ── Connect to PostgreSQL ──────────────────────────────────────────────────
local db = pgmoon.new({
    host     = db_host,
    port     = db_port,
    database = db_name,
    user     = db_user,
    password = db_password,
})

print("Connecting to " .. db_name .. "@" .. db_host .. ":" .. db_port .. "...")
local ok, conn_err = db:connect()
if not ok then
    print("ERROR: Could not connect to database: " .. tostring(conn_err))
    print("Make sure your environment variables are set (source .env).")
    os.exit(1)
end
print("Connected.")
print("")

-- ── Counters ───────────────────────────────────────────────────────────────
local total_upgraded = 0
local total_skipped  = 0
local total_errors   = 0

print("=== bcrypt password wrapping migration ===")
print("Cost factor: " .. BCRYPT_LOG_ROUNDS)
print("Batch size:  " .. BATCH_SIZE)
print("")

-- ── Count users needing migration ──────────────────────────────────────────
local count_result, count_err = db:query(
    "SELECT count(*) AS cnt FROM users WHERE password_version = 0"
)
if not count_result then
    print("ERROR: Could not count users: " .. tostring(count_err))
    os.exit(1)
end

local total_to_migrate = tonumber(count_result[1].cnt)
print("Users to migrate: " .. total_to_migrate)

if total_to_migrate == 0 then
    print("Nothing to do. All users are already on password_version >= 1.")
    db:disconnect()
    os.exit(0)
end

print("Starting migration...")
print("")

-- ── Process in batches ─────────────────────────────────────────────────────
-- We re-query each batch because we update password_version as we go,
-- so the WHERE clause naturally advances past already-migrated rows.
while true do
    local users, query_err = db:query(
        "SELECT id, username, password FROM users " ..
        "WHERE password_version = 0 " ..
        "ORDER BY id ASC LIMIT " .. BATCH_SIZE
    )

    if not users then
        print("ERROR: batch query failed: " .. tostring(query_err))
        break
    end

    if #users == 0 then
        break
    end

    for _, user in ipairs(users) do
        -- Guard: skip users whose password is already a bcrypt hash
        -- (shouldn't happen, but be safe).
        if user.password and user.password:sub(1, 4) == "$2b$" then
            total_skipped = total_skipped + 1
            -- Still mark it as version 1 so we don't re-process it.
            db:query(
                "UPDATE users SET password_version = 1 WHERE id = " ..
                db:escape_literal(user.id)
            )
        else
            local hash_ok, new_hash = pcall(bcrypt.digest, user.password, BCRYPT_LOG_ROUNDS)
            if hash_ok then
                local update_result, update_err = db:query(
                    "UPDATE users SET password = " ..
                    db:escape_literal(new_hash) ..
                    ", password_version = 1 WHERE id = " ..
                    db:escape_literal(user.id)
                )
                if update_result then
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

    print("  progress: " .. (total_upgraded + total_skipped) ..
          " / " .. total_to_migrate ..
          " (" .. total_errors .. " errors)")
end

-- ── Summary ────────────────────────────────────────────────────────────────
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

db:disconnect()
