-- Minimal JWT (RFC 7519) support for LTI 1.3
-- ==========================================
--
-- The Snap!Cloud runs in OpenResty so it has access to luaossl (``openssl.*``)
-- and resty primitives. Rather than pulling in a full JWT library, this module
-- implements just the pieces needed to act as an LTI 1.3 Tool: it can verify
-- an id_token signed by an LTI platform (RS256), build a JWK from an RSA
-- public key, and parse a JWKS entry back into an openssl pkey.
--
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

local pkey = require('openssl.pkey')
local digest = require('openssl.digest')
local cjson = require('cjson')
local encoding = require('lapis.util.encoding')

local M = {}

-- Base64url helpers --------------------------------------------------------

local function to_base64url(bytes)
    local b64 = encoding.encode_base64(bytes)
    -- strip padding and translate alphabet
    b64 = b64:gsub('=', ''):gsub('+', '-'):gsub('/', '_')
    return b64
end

local function from_base64url(s)
    if not s then return nil end
    local fixed = s:gsub('-', '+'):gsub('_', '/')
    -- re-pad
    local pad = (4 - (#fixed % 4)) % 4
    fixed = fixed .. string.rep('=', pad)
    return encoding.decode_base64(fixed)
end

M.to_base64url = to_base64url
M.from_base64url = from_base64url

-- JSON helpers -------------------------------------------------------------

local function json_decode(s)
    if not s then return nil end
    local ok, result = pcall(cjson.decode, s)
    if not ok then return nil end
    return result
end

local function json_encode(obj)
    return cjson.encode(obj)
end

-- Parse a JWT into its three parts without validating anything.
-- Returns header (table), payload (table), raw signing input (string),
-- raw signature (bytes).
function M.decode(token)
    if type(token) ~= 'string' then
        return nil, 'token is not a string'
    end
    local h64, p64, s64 = token:match('^([^%.]+)%.([^%.]+)%.([^%.]+)$')
    if not h64 then
        return nil, 'token is not a well-formed JWT'
    end
    local header = json_decode(from_base64url(h64))
    local payload = json_decode(from_base64url(p64))
    if not header or not payload then
        return nil, 'token header or payload is not valid JSON'
    end
    local signature = from_base64url(s64)
    if not signature then
        return nil, 'token signature could not be decoded'
    end
    return {
        header = header,
        payload = payload,
        signing_input = h64 .. '.' .. p64,
        signature = signature
    }
end

-- DER/PEM helpers ----------------------------------------------------------
--
-- luaossl's pkey.new({type="RSA", n=..., e=...}) ignores the supplied bignums
-- and generates a fresh random key, so we cannot use it to build a public key
-- from a JWK directly. Instead we assemble a SubjectPublicKeyInfo DER blob by
-- hand and parse that back in as a PEM.
local function asn1_length(n)
    if n < 0x80 then
        return string.char(n)
    end
    local bytes = {}
    while n > 0 do
        table.insert(bytes, 1, string.char(n % 256))
        n = math.floor(n / 256)
    end
    return string.char(0x80 + #bytes) .. table.concat(bytes)
end

local function asn1_tlv(tag, body)
    return string.char(tag) .. asn1_length(#body) .. body
end

local function asn1_integer(bin)
    -- INTEGER is signed, so prepend a 0x00 byte if the high bit is set.
    if bin:byte(1) >= 0x80 then
        bin = '\0' .. bin
    end
    return asn1_tlv(0x02, bin)
end

local function asn1_sequence(body)
    return asn1_tlv(0x30, body)
end

local function asn1_bitstring(body)
    return asn1_tlv(0x03, '\0' .. body)
end

-- Fixed AlgorithmIdentifier for rsaEncryption (OID 1.2.840.113549.1.1.1).
local RSA_ALGORITHM_IDENTIFIER =
    asn1_sequence('\6\9\42\134\72\134\247\13\1\1\1' .. '\5\0')

local function rsa_spki_pem(n_bin, e_bin)
    local rsa_pubkey = asn1_sequence(asn1_integer(n_bin) .. asn1_integer(e_bin))
    local spki = asn1_sequence(RSA_ALGORITHM_IDENTIFIER .. asn1_bitstring(rsa_pubkey))
    local b64 = encoding.encode_base64(spki)
    local lines = { '-----BEGIN PUBLIC KEY-----' }
    for i = 1, #b64, 64 do
        table.insert(lines, b64:sub(i, i + 63))
    end
    table.insert(lines, '-----END PUBLIC KEY-----')
    return table.concat(lines, '\n') .. '\n'
end

-- Load a JWK (table) into an openssl.pkey. Only RSA keys are supported,
-- since LTI 1.3 platforms are expected to use RS256-signed keys (JWA).
function M.jwk_to_pkey(jwk)
    if type(jwk) ~= 'table' then
        return nil, 'jwk is not a table'
    end
    if jwk.kty ~= 'RSA' then
        return nil, 'only RSA JWKs are supported (got kty=' ..
            tostring(jwk.kty) .. ')'
    end
    local n_bin = from_base64url(jwk.n)
    local e_bin = from_base64url(jwk.e)
    if not n_bin or not e_bin then
        return nil, 'jwk is missing n or e'
    end
    local pem = rsa_spki_pem(n_bin, e_bin)
    local ok, key = pcall(pkey.new, pem)
    if not ok or not key then
        return nil, 'could not construct RSA public key from jwk: ' ..
            tostring(key)
    end
    return key
end

-- Exposed for tests / unusual callers.
M._rsa_spki_pem = rsa_spki_pem

-- Render an openssl.pkey as a JWK (public-only). Useful for building the
-- tool's JWKS endpoint.
function M.pkey_to_jwk(key, kid)
    local params = key:getParameters()
    if not params or not params.n or not params.e then
        return nil, 'pkey has no RSA parameters'
    end
    return {
        kty = 'RSA',
        alg = 'RS256',
        use = 'sig',
        kid = kid,
        n = to_base64url(params.n:toBinary()),
        e = to_base64url(params.e:toBinary())
    }
end

-- Verify a JWT. Options table supports:
--   key         - an openssl.pkey (public) to use for verification
--   jwks        - { keys = { ... } } table to select a key by kid from
--   algorithms  - array of allowed algorithms (defaults to {"RS256"})
--   iss         - expected issuer claim
--   aud         - expected audience claim (string or array)
--   nonce       - expected nonce claim
--   leeway      - clock-skew allowance in seconds (default 60)
--   now         - override current time (for tests)
-- Returns (payload, nil) on success, (nil, err) on failure.
function M.verify(token, opts)
    opts = opts or {}
    local decoded, err = M.decode(token)
    if not decoded then return nil, err end

    local alg = decoded.header.alg
    local allowed = opts.algorithms or { 'RS256' }
    local alg_ok = false
    for _, a in ipairs(allowed) do
        if a == alg then alg_ok = true; break end
    end
    if not alg_ok then
        return nil, 'jwt alg ' .. tostring(alg) .. ' is not allowed'
    end

    -- Pick a public key to verify with.
    local key = opts.key
    if not key and opts.jwks then
        for _, jwk in ipairs(opts.jwks.keys or {}) do
            if jwk.kid == decoded.header.kid then
                key, err = M.jwk_to_pkey(jwk)
                if not key then return nil, err end
                break
            end
        end
        if not key then
            return nil,
                'no matching key in jwks for kid=' ..
                tostring(decoded.header.kid)
        end
    end
    if not key then
        return nil, 'no verification key supplied'
    end

    -- RS256 => RSA + SHA-256. We also accept RS384/RS512 because they're
    -- required by JWA and some platforms rotate up to them.
    local md
    if alg == 'RS256' then
        md = digest.new('SHA256')
    elseif alg == 'RS384' then
        md = digest.new('SHA384')
    elseif alg == 'RS512' then
        md = digest.new('SHA512')
    else
        return nil, 'unsupported alg ' .. tostring(alg)
    end
    md:update(decoded.signing_input)
    local ok = key:verify(decoded.signature, md)
    if not ok then
        return nil, 'jwt signature is invalid'
    end

    local p = decoded.payload
    local leeway = opts.leeway or 60
    local now = opts.now or os.time()
    if p.exp and tonumber(p.exp) and (tonumber(p.exp) + leeway) < now then
        return nil, 'jwt has expired'
    end
    if p.nbf and tonumber(p.nbf) and tonumber(p.nbf) > (now + leeway) then
        return nil, 'jwt is not yet valid'
    end
    if opts.iss and p.iss ~= opts.iss then
        return nil, 'jwt iss mismatch'
    end
    if opts.aud then
        local aud = p.aud
        if type(aud) == 'string' then
            if aud ~= opts.aud then
                return nil, 'jwt aud mismatch'
            end
        elseif type(aud) == 'table' then
            local matched = false
            for _, v in ipairs(aud) do
                if v == opts.aud then matched = true; break end
            end
            if not matched then
                return nil, 'jwt aud mismatch'
            end
        else
            return nil, 'jwt has no aud claim'
        end
    end
    if opts.nonce and p.nonce ~= opts.nonce then
        return nil, 'jwt nonce mismatch'
    end

    return p, nil, decoded
end

-- Sign a payload using an RS256 RSA key. Returns the encoded JWT.
function M.sign(payload, private_key, opts)
    opts = opts or {}
    local header = {
        alg = opts.alg or 'RS256',
        typ = 'JWT',
        kid = opts.kid
    }
    local h64 = to_base64url(json_encode(header))
    local p64 = to_base64url(json_encode(payload))
    local signing_input = h64 .. '.' .. p64
    local md = digest.new('SHA256')
    md:update(signing_input)
    local sig = private_key:sign(md)
    return signing_input .. '.' .. to_base64url(sig)
end

return M
