-- Salting and hashing
-- ===================
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

local resty_sha512 = package.loaded.resty_sha512
local resty_string = package.loaded.resty_string
local resty_random = package.loaded.resty_random
local bcrypt = require('bcrypt')

-- Bcrypt cost factor. 12 is the OWASP-recommended minimum (2^12 = 4096
-- iterations). Tune this up over time as hardware improves.
local BCRYPT_LOG_ROUNDS = 12

-- Password schemes:
--   v1 (bcrypt-wrapped):  bcrypt(sha512(client_prehash .. salt))
--                         output of the one-time bulk migration from the
--                         original SHA-512 scheme. Detected by salt being
--                         a non-empty string.
--   v2 (native bcrypt):   bcrypt(client_prehash)
--                         new accounts and JIT upgrades on successful login.
--                         Detected by salt being NULL or empty.

-- SHA-512 of (input .. salt). Used by v1 verification (to recompute the
-- inner hash before bcrypt-verifying it) and as a generic SHA-512 helper
-- for secure_token and for server-side prehashing of teacher-created learner
-- passwords (which arrive as plaintext rather than client-prehashed).
hash_password = function (password, salt)
    local sha512 = resty_sha512:new()
    sha512:update(password .. salt)
    return resty_string.to_hex(sha512:final())
end

-- Generate a cryptographically strong 16-byte hex salt. Still used as random
-- entropy for secure_token; v2 bcrypt manages its own salt internally.
secure_salt = function ()
    local strong_random = resty_random.bytes(16, true)
    while strong_random == nil do
        strong_random = resty_random.bytes(16, true)
    end
    return resty_string.to_hex(strong_random)
end

-- Generate a random secure token for verification / password reset links.
secure_token = function ()
    return hash_password(secure_salt(), secure_salt())
end

-- =========================================================================
-- New bcrypt-based password functions
-- =========================================================================

--- Hash a client-prehashed password with bcrypt for new accounts (version 2).
-- @param prehash  string  The SHA-512 hex string the client sent.
-- @return string  A bcrypt hash string (includes algorithm, cost, salt, and
--                 digest — everything needed to verify later).
bcrypt_hash = function (prehash)
    return bcrypt.digest(prehash, BCRYPT_LOG_ROUNDS)
end

--- Verify a password against a stored hash.
--
-- The stored scheme is inferred from the salt:
--   * non-empty salt  ->  v1: bcrypt(sha512(prehash .. salt))
--   * empty/NULL salt ->  v2: bcrypt(prehash)
--
-- @param prehash      string  The SHA-512 hex digest the client sent.
-- @param stored_hash  string  The hash from the database (users.password).
-- @param salt         string  The per-user salt (users.salt). Empty/NULL for v2.
-- @return boolean  true if the password matches.
verify_password = function (prehash, stored_hash, salt)
    -- A missing prehash (e.g. a login POST with no password field) must be
    -- treated as a failed authentication, not a 500. Bailing here prevents
    -- the nil from reaching hash_password's string concat or bcrypt.verify.
    if prehash == nil or stored_hash == nil then
        return false
    end

    if salt and salt ~= '' then
        local legacy_hash = hash_password(prehash, salt)
        return bcrypt.verify(legacy_hash, stored_hash)
    else
        return bcrypt.verify(prehash, stored_hash)
    end
end

--- Upgrade a user's password to native bcrypt (v2) after a successful login.
-- Call this only AFTER verify_password returns true. Clearing the salt is
-- what marks the row as v2 — once empty, future logins skip the inner
-- SHA-512 step.
--
-- @param user     The Lapis model row (must support :update()).
-- @param prehash  string  The SHA-512 hex digest the client sent.
-- @return boolean  true if the upgrade happened, false if already on v2.
upgrade_password_to_bcrypt = function (user, prehash)
    if not user.salt or user.salt == '' then
        return false
    end
    user:update({
        password = bcrypt_hash(prehash),
        salt = '',
    })
    return true
end
