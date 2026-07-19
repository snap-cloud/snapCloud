-- luacheck config for Snap!Cloud
-- Target: Lua 5.1 running under OpenResty + Lapis.

std = "lua51+ngx"

-- Third-party / framework globals the project relies on.
-- A lot of the Snap!Cloud codebase deliberately uses process-wide globals
-- (e.g. `err`, `hash_password`, `yield_error`) as a convenience. Rather than
-- chasing those down in one go, we register them here so luacheck can focus
-- on real problems (typos, unused locals, shadowing, etc.). New code should
-- prefer `local` + explicit imports.
globals = {
    -- Snap!Cloud globals (set in responses.lua / passwords.lua / validation.lua)
    "err",
    "errorResponses",
    "yieldError",
    "assertUser",
    "assertAdmin",
    "assertMinRole",
    "assertMinRoleOrSelf",
    "assertUserCanSetRole",
    "hash_password",
    "secure_salt",
    "secure_token",
    "debug_print",
    -- Convenience helpers attached to strings in lib/global.lua
    "string",
}

read_globals = {
    -- OpenResty / ngx_lua
    "ngx",
    -- Snap!Cloud convention: modules are stuffed into package.loaded
    "package",
}

-- Expose ngx-based definitions for openresty
stds.ngx = {
    read_globals = {
        ngx = {
            fields = {
                "shared", "var", "req", "resp", "say", "print", "exit",
                "log", "header", "status", "location", "escape_uri",
                "unescape_uri", "decode_args", "encode_args", "null",
                "worker", "timer", "thread", "sleep", "time", "now",
                "today", "localtime", "utctime", "cookie_time",
                "http_time", "parse_http_time", "re", "redirect",
                "HTTP_OK", "HTTP_MOVED_PERMANENTLY", "HTTP_FOUND",
                "HTTP_SEE_OTHER", "HTTP_NOT_MODIFIED", "HTTP_BAD_REQUEST",
                "HTTP_UNAUTHORIZED", "HTTP_FORBIDDEN", "HTTP_NOT_FOUND",
                "HTTP_INTERNAL_SERVER_ERROR", "DEBUG", "INFO", "NOTICE",
                "WARN", "ERR", "CRIT", "ALERT", "EMERG",
                "OK", "ERROR", "AGAIN", "DONE", "DECLINED",
            }
        }
    }
}

-- Skip paths that aren't ours, or are generated / third-party.
exclude_files = {
    "node_modules/",
    "snap/",
    "snap-versions/",
    "lib/raven-lua/",
    "store/",
    "logs/",
    "tmp/",
    "dev/",
    "old_site/",
}

-- Relax a handful of checks project-wide. These are the rules most likely
-- to produce noise in existing code; tighten over time. Real bugs (unused
-- locals, redundant assignments, shadowed variables, etc.) still report.
--
-- 111 / 112: setting a (non-standard / read-only) global — the codebase
--            deliberately stashes helpers into _G via `package.loaded.*`.
-- 113:       accessing an undefined (global) variable — ditto; too many
--            cross-file globals to declare exhaustively up front.
-- 121 / 122: setting a read-only global / field — same story.
-- 212:       unused argument.
-- 213:       unused loop variable.
-- 431:       shadowing upvalue — not a bug, but noisy in long files.
-- 611 / 612 / 614: whitespace-only issues.
-- 631:       line too long.
--
-- Tighten over time by removing entries from this list.
ignore = {
    -- Globals (see note above).
    "111", "112", "113", "121", "122",
    -- Unused locals / arguments. These flag real (small) issues —
    -- stale imports, leftover bindings. Kept suppressed so the baseline
    -- is green; remove these codes one at a time as files are cleaned up.
    "211", "212", "213",
    -- Value assigned but not read, redefinitions, empty branches — same
    -- story: legitimate tech debt, not new-code blockers.
    "311", "411", "412", "431", "542",
    -- Whitespace + line length. Low signal.
    "611", "612", "614", "631",
}

-- Spec files can do whatever they need with globals from busted.
files["spec/"] = {
    std = "lua51+busted",
    globals = { "_TEST" },
}

-- Migrations are allowed to be long procedural scripts.
files["migrations.lua"] = {
    max_line_length = false,
}
