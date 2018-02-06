--[[
    Shared utilities for the Snap!Cloud

]]

local resty_random = require ("resty.random")
local str = require("resty.string")

local function secureSalt()
    local strong_random = resty_random.bytes(16,true)
        -- attempt to generate 16 bytes of
        -- cryptographically strong random data
    while strong_random == nil do
        strong_random = resty_random.bytes(16,true)
    end

    return str.to_hex(strong_random)
end

return {
    secureSalt = secureSalt
}