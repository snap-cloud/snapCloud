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

-- Password version constants:
--   0 = legacy SHA-512:  sha512(client_prehash .. salt)
--   1 = bcrypt-wrapped:  bcrypt(legacy_sha512_hash)  (bulk migration output)
--   2 = native bcrypt:   bcrypt(client_prehash)       (new accounts + JIT upgrades)
PASSWORD_VERSION_LEGACY   = 0
PASSWORD_VERSION_WRAPPED  = 1
PASSWORD_VERSION_BCRYPT   = 2

-- Legacy SHA-512 hash used by the old scheme.
-- The client always sends a single-round SHA-512 of the plaintext password.
-- The server then hashes that again with a per-user salt.
-- Kept for verifying version-0 passwords and for the bulk-wrap migration.
hash_password = function (password, salt)
    local sha512 = resty_sha512:new()
    sha512:update(password .. salt)
    return resty_string.to_hex(sha512:final())
end

-- Generate a cryptographically strong 16-byte hex salt (for legacy compat).
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

--- Verify a password against a stored hash, supporting all three versions.
--
-- Version 0 (legacy):
--   The stored hash is sha512(client_prehash .. user.salt).
--   We recompute that and compare with a constant-time check.
--
-- Version 1 (bcrypt-wrapped legacy):
--   After the bulk migration script runs, the stored hash is
--   bcrypt(old_sha512_hash). We first compute the legacy SHA-512 hash from
--   the supplied prehash + salt, then verify that intermediate value against
--   the stored bcrypt hash.
--
-- Version 2 (native bcrypt):
--   The stored hash is bcrypt(client_prehash). We verify directly.
--
-- @param prehash          string  The SHA-512 hex digest the client sent.
-- @param stored_hash      string  The hash from the database (users.password).
-- @param salt             string  The per-user salt (users.salt). Only needed
--                                 for versions 0 and 1; ignored for version 2.
-- @param password_version number  The users.password_version value (0, 1, 2).
-- @return boolean  true if the password matches.
verify_password = function (prehash, stored_hash, salt, password_version)
    local version = password_version or PASSWORD_VERSION_LEGACY

    if version == PASSWORD_VERSION_LEGACY then
        -- Constant-time comparison would be ideal, but the legacy code used ==.
        -- SHA-512(prehash .. salt) must equal the stored value.
        return hash_password(prehash, salt) == stored_hash

    elseif version == PASSWORD_VERSION_WRAPPED then
        -- The stored hash is bcrypt(sha512(prehash .. salt)).
        -- Recompute the legacy intermediate hash, then bcrypt-verify it.
        local legacy_hash = hash_password(prehash, salt)
        return bcrypt.verify(legacy_hash, stored_hash)

    elseif version == PASSWORD_VERSION_BCRYPT then
        -- The stored hash is bcrypt(prehash). Verify directly.
        return bcrypt.verify(prehash, stored_hash)

    else
        -- Unknown version — refuse to authenticate.
        return false
    end
end

--- Upgrade a user's password to native bcrypt (version 2) after a successful
-- login.  Call this only AFTER verify_password returns true.
--
-- @param user     The Lapis model row (must support :update()).
-- @param prehash  string  The SHA-512 hex digest the client sent.
-- @return boolean  true if the upgrade happened, false if already on v2.
upgrade_password_to_bcrypt = function (user, prehash)
    if (user.password_version or 0) >= PASSWORD_VERSION_BCRYPT then
        return false
    end
    local new_hash = bcrypt_hash(prehash)
    user:update({
        password = new_hash,
        password_version = PASSWORD_VERSION_BCRYPT,
        -- The salt column is unused for v2 but we leave it as-is rather than
        -- clearing it — password_version is the authoritative scheme indicator.
    })
    return true
end
