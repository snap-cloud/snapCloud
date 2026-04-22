-- S3-compatible client (AWS Signature V4)
-- =======================================
--
-- A minimal client for S3-compatible object stores (Cloudflare R2, MinIO, AWS).
-- Implements only the operations we need: PutObject, GetObject, CopyObject,
-- DeleteObject, HeadObject, and presigned GET URL generation.
--
-- Configuration is read from the shared config (see config.lua):
--   endpoint         -- full URL, e.g. https://<acct>.r2.cloudflarestorage.com
--   bucket           -- R2 bucket / MinIO bucket name
--   access_key_id    -- S3 access key
--   secret_access_key
--   region           -- region name (R2 is always 'auto')
--   public_host      -- optional, used for presigned URLs if different
--                       from endpoint (custom domain, reverse proxy, etc.)
--
-- Written for Snap!Cloud, licensed AGPL.

local http = require('resty.http')
local resty_sha256 = require('resty.sha256')
local resty_string = require('resty.string')
local encoding = require('lapis.util.encoding')
local util = require('lapis.util')

local config = package.loaded.config

local s3 = {}

-- Helpers -----------------------------------------------------------------

local function hex(s)
    return resty_string.to_hex(s)
end

local function sha256_hex(s)
    local d = resty_sha256:new()
    d:update(s or '')
    return hex(d:final())
end

local function hmac(key, data)
    return encoding.hmac_sha256(key, data)
end

-- RFC3986 percent-encoding. Unlike ngx.escape_uri, we must NOT encode the
-- unreserved set (A-Z a-z 0-9 - _ . ~). Slash handling is controlled by the
-- caller because path segments need / preserved while query values don't.
local function rfc3986(s, keep_slash)
    return (s:gsub('[^%w%-%._~' .. (keep_slash and '/' or '') .. ']',
        function (c)
            return string.format('%%%02X', string.byte(c))
        end))
end

local function amz_date(ts)
    return os.date('!%Y%m%dT%H%M%SZ', ts)
end

local function amz_shortdate(ts)
    return os.date('!%Y%m%d', ts)
end

local function conf()
    local c = config.s3 or {}
    return {
        endpoint = c.endpoint,
        bucket = c.bucket,
        access_key_id = c.access_key_id,
        secret_access_key = c.secret_access_key,
        region = c.region or 'auto',
        public_host = c.public_host or c.endpoint,
    }
end

function s3.is_configured()
    local c = conf()
    return c.endpoint and c.bucket
        and c.access_key_id and c.secret_access_key
        and c.endpoint ~= '' and c.bucket ~= ''
end

-- Parse an endpoint URL into { scheme, host, port, base_path }. S3-compatible
-- stores expose the bucket as either a subdomain (virtual-hosted style) or a
-- path prefix (path style). MinIO defaults to path style; R2 accepts both but
-- we use path style because it's simpler and works with custom domains.
local function parse_endpoint(url)
    local scheme, host, rest = url:match('^(https?)://([^/]+)(/?.*)$')
    if not scheme then
        error('invalid S3 endpoint: ' .. tostring(url))
    end
    local port
    host, port = host:match('^([^:]+):?(%d*)$')
    port = tonumber(port)
        or (scheme == 'https' and 443 or 80)
    return {
        scheme = scheme,
        host = host,
        port = port,
        base_path = (rest ~= '' and rest) or '/',
    }
end

-- Build the canonical request, signed headers, and signature. Returns a
-- table of headers to attach to the HTTP request.
local function sign(method, key, query_params, body, extra_headers, ts)
    local c = conf()
    local endpoint = parse_endpoint(c.endpoint)
    ts = ts or ngx.time()

    local path = endpoint.base_path
    if path:sub(-1) ~= '/' then path = path .. '/' end
    path = path .. c.bucket .. '/' .. rfc3986(key, true)

    -- Canonical query string (sorted, each key/value rfc3986-encoded)
    local qp = query_params or {}
    local names = {}
    for name, _ in pairs(qp) do table.insert(names, name) end
    table.sort(names)
    local qs_parts = {}
    for _, name in ipairs(names) do
        table.insert(qs_parts,
            rfc3986(name) .. '=' .. rfc3986(tostring(qp[name])))
    end
    local canonical_query = table.concat(qs_parts, '&')

    local payload_hash = sha256_hex(body or '')

    local host_header = endpoint.host
    if (endpoint.scheme == 'http' and endpoint.port ~= 80)
            or (endpoint.scheme == 'https' and endpoint.port ~= 443) then
        host_header = host_header .. ':' .. endpoint.port
    end

    local headers = {
        host = host_header,
        ['x-amz-date'] = amz_date(ts),
        ['x-amz-content-sha256'] = payload_hash,
    }
    if extra_headers then
        for k, v in pairs(extra_headers) do headers[k:lower()] = v end
    end

    -- Canonical headers
    local header_names = {}
    for name, _ in pairs(headers) do table.insert(header_names, name) end
    table.sort(header_names)
    local canonical_headers_parts = {}
    for _, name in ipairs(header_names) do
        table.insert(canonical_headers_parts,
            name .. ':' .. tostring(headers[name]):gsub('%s+', ' '):gsub(
                '^%s*(.-)%s*$', '%1') .. '\n')
    end
    local canonical_headers = table.concat(canonical_headers_parts)
    local signed_headers = table.concat(header_names, ';')

    local canonical_request = table.concat({
        method,
        path,
        canonical_query,
        canonical_headers,
        signed_headers,
        payload_hash,
    }, '\n')

    local short = amz_shortdate(ts)
    local scope = short .. '/' .. c.region .. '/s3/aws4_request'
    local string_to_sign = table.concat({
        'AWS4-HMAC-SHA256',
        headers['x-amz-date'],
        scope,
        sha256_hex(canonical_request),
    }, '\n')

    local k_date = hmac('AWS4' .. c.secret_access_key, short)
    local k_region = hmac(k_date, c.region)
    local k_service = hmac(k_region, 's3')
    local k_signing = hmac(k_service, 'aws4_request')
    local signature = hex(hmac(k_signing, string_to_sign))

    headers['authorization'] =
        'AWS4-HMAC-SHA256 Credential=' .. c.access_key_id .. '/' .. scope
        .. ', SignedHeaders=' .. signed_headers
        .. ', Signature=' .. signature

    return {
        url = endpoint.scheme .. '://' .. host_header .. path
            .. (canonical_query ~= '' and ('?' .. canonical_query) or ''),
        headers = headers,
    }
end

-- HTTP dispatch. Returns (body, status_code, response_headers, err).
local function send(method, key, opts)
    opts = opts or {}
    local signed = sign(method, key, opts.query, opts.body, opts.headers)
    local client = http.new()
    client:set_timeout(opts.timeout or 30000)
    local res, err = client:request_uri(signed.url, {
        method = method,
        headers = signed.headers,
        body = opts.body,
    })
    if not res then return nil, nil, nil, err end
    return res.body, res.status, res.headers, nil
end

-- Public API --------------------------------------------------------------

function s3.put(key, body, content_type)
    local _, status, _, err = send('PUT', key, {
        body = body or '',
        headers = content_type
            and { ['content-type'] = content_type } or nil,
    })
    if err then return false, err end
    if status < 200 or status >= 300 then
        return false, 's3 PUT failed: ' .. tostring(status)
    end
    return true
end

function s3.get(key)
    local body, status, _, err = send('GET', key)
    if err then return nil, err end
    if status == 404 then return nil, nil end
    if status < 200 or status >= 300 then
        return nil, 's3 GET failed: ' .. tostring(status)
    end
    return body
end

function s3.head(key)
    local _, status, headers, err = send('HEAD', key)
    if err then return nil, err end
    if status == 404 then return nil end
    if status < 200 or status >= 300 then
        return nil, 's3 HEAD failed: ' .. tostring(status)
    end
    return headers
end

function s3.exists(key)
    local h, err = s3.head(key)
    if err then return false, err end
    return h ~= nil
end

function s3.copy(src_key, dst_key)
    local c = conf()
    local _, status, _, err = send('PUT', dst_key, {
        headers = {
            ['x-amz-copy-source'] = '/' .. c.bucket .. '/'
                .. rfc3986(src_key, true),
        },
    })
    if err then return false, err end
    if status < 200 or status >= 300 then
        return false, 's3 COPY failed: ' .. tostring(status)
    end
    return true
end

function s3.delete(key)
    local _, status, _, err = send('DELETE', key)
    if err then return false, err end
    -- S3 returns 204 on success; some impls return 200.
    if status ~= 204 and (status < 200 or status >= 300) then
        return false, 's3 DELETE failed: ' .. tostring(status)
    end
    return true
end

-- Generate a presigned GET URL for direct client download. The URL is valid
-- for `expires_seconds` seconds and encodes the bucket + key + expiry into
-- a SigV4 signature so the object store can verify authenticity without
-- a round-trip to Snap!Cloud.
function s3.presign_get(key, expires_seconds, response_content_type)
    local c = conf()
    local endpoint = parse_endpoint(c.endpoint)
    local ts = ngx.time()
    expires_seconds = expires_seconds or 300

    local short = amz_shortdate(ts)
    local scope = short .. '/' .. c.region .. '/s3/aws4_request'

    local host_header = endpoint.host
    if (endpoint.scheme == 'http' and endpoint.port ~= 80)
            or (endpoint.scheme == 'https' and endpoint.port ~= 443) then
        host_header = host_header .. ':' .. endpoint.port
    end

    local query = {
        ['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256',
        ['X-Amz-Credential'] = c.access_key_id .. '/' .. scope,
        ['X-Amz-Date'] = amz_date(ts),
        ['X-Amz-Expires'] = tostring(expires_seconds),
        ['X-Amz-SignedHeaders'] = 'host',
    }
    if response_content_type then
        query['response-content-type'] = response_content_type
    end

    local path = endpoint.base_path
    if path:sub(-1) ~= '/' then path = path .. '/' end
    path = path .. c.bucket .. '/' .. rfc3986(key, true)

    local names = {}
    for n, _ in pairs(query) do table.insert(names, n) end
    table.sort(names)
    local qs_parts = {}
    for _, n in ipairs(names) do
        table.insert(qs_parts,
            rfc3986(n) .. '=' .. rfc3986(tostring(query[n])))
    end
    local canonical_query = table.concat(qs_parts, '&')

    local canonical_request = table.concat({
        'GET',
        path,
        canonical_query,
        'host:' .. host_header .. '\n',
        'host',
        'UNSIGNED-PAYLOAD',
    }, '\n')

    local string_to_sign = table.concat({
        'AWS4-HMAC-SHA256',
        query['X-Amz-Date'],
        scope,
        sha256_hex(canonical_request),
    }, '\n')

    local k_date = hmac('AWS4' .. c.secret_access_key, short)
    local k_region = hmac(k_date, c.region)
    local k_service = hmac(k_region, 's3')
    local k_signing = hmac(k_service, 'aws4_request')
    local signature = hex(hmac(k_signing, string_to_sign))

    -- Use public_host for the returned URL if configured (CDN / custom domain)
    local public_base = c.public_host or c.endpoint
    local public_endpoint = parse_endpoint(public_base)
    local public_host_header = public_endpoint.host
    if (public_endpoint.scheme == 'http' and public_endpoint.port ~= 80)
            or (public_endpoint.scheme == 'https'
                    and public_endpoint.port ~= 443) then
        public_host_header = public_host_header .. ':' .. public_endpoint.port
    end

    return public_endpoint.scheme .. '://' .. public_host_header
        .. path .. '?' .. canonical_query
        .. '&X-Amz-Signature=' .. signature
end

return s3
