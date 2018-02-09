-- Salting and hashing
-- ===================
--
-- Written by Bernat Romagosa
--
-- Copyright (C) 2018 by Bernat Romagosa
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

hash_password = function (password, salt)
    -- we're following the same policy as the old cloud in order to keep user 
    -- passwords unchanged
    -- "password" comes prehashed from the client
    local sha512 = resty_sha512:new()
    sha512:update(password .. salt)
    return resty_string.to_hex(sha512:final())
end

secure_salt = function ()
    local strong_random = resty_random.bytes(16, true)
    -- attempt to generate 16 bytes of
    -- cryptographically strong random data
    while strong_random == nil do
        strong_random = resty_random.bytes(16, true)
    end

    return resty_string.to_hex(strong_random)
end

secure_token = function ()
    -- generate a random secure token that can be used for user verification
    -- and password reset
    return hash_password(secure_salt(), secure_salt())
end

random_password = function ()
    -- generate a random 8 character password
    local password = resty_string.to_hex(resty_random.bytes(4, true))
    -- we now calculate the password prehash
    local sha512 = resty_sha512:new()
    local prehash = sha512:update(password)
    return password, resty_string.to_hex(sha512:final())
end
