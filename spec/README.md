# Snap!Cloud test suite

The suite is split into four independently-reported CI statuses, each of
which maps to a job in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml):

| Status           | Job name     | What it runs                                                |
| ---------------- | ------------ | ----------------------------------------------------------- |
| `Luacheck`       | `luacheck`   | `luacheck .` using [`.luacheckrc`](../.luacheckrc)          |
| `Busted (Lua)`   | `busted`     | `busted` specs under `spec/unit/` and `spec/models/`         |
| `Playwright (e2e)` | `playwright` | Browser specs under `spec/e2e/`, excluding `@axe`-tagged    |
| `Axe-core (a11y)` | `axe`        | Browser specs under `spec/e2e/` tagged `@axe`               |

Keeping these separate means a broken end-to-end test doesn't hide a new
accessibility regression (or vice versa) in the PR check summary.

## Running locally

The repo-level `Makefile` exposes the same shape as CI:

```bash
make lint        # luacheck
make test-lua    # busted
make test-e2e    # playwright, browser specs only
make test-a11y   # playwright, axe specs only
make test        # everything
```

Or directly:

```bash
LAPIS_ENVIRONMENT=test DATABASE_NAME=snapcloud_test busted
LAPIS_ENVIRONMENT=test DATABASE_NAME=snapcloud_test npx playwright test
```

### Database safety

Specs refuse to start if `DATABASE_NAME` is set to anything other than
`snapcloud_test`. The check lives in two places:

1. [`spec/spec_helper.lua`](spec_helper.lua) — fails fast at startup.
2. [`spec/support/db_helper.lua`](support/db_helper.lua) — re-checks
   on every `db()`/`truncate_all()` call (defense in depth).

If you see "Refusing to run: DATABASE_NAME=…", unset the variable or
export `DATABASE_NAME=snapcloud_test`.

### One-time setup

```bash
# Postgres
createdb snapcloud_test
psql -d snapcloud_test -f db/schema.sql
psql -d snapcloud_test -f db/seeds.sql

# Lua + busted
luarocks install --lua-version=5.1 busted luacheck luacov

# Node + Playwright
npm install
npx playwright install --with-deps chromium
```

## Directory layout

```
spec/
├── spec_helper.lua          # env checks, loaded by busted before every spec
├── support/
│   ├── db_helper.lua        # test DB wrapper + TRUNCATE helpers
│   └── factories.lua        # fixture-style record constructors
├── unit/                    # pure-Lua specs, no DB needed
│   ├── util_spec.lua
│   └── cors_spec.lua
├── models/                  # specs that exercise Lapis models against PG
│   └── users_spec.lua
├── e2e/                     # Playwright browser specs
│   ├── homepage.spec.js
│   └── accessibility.spec.js
└── data/                    # fixture files (see data/README.md)
    ├── projects/
    └── users/
```

## Writing a new test

### Busted (Lua)

- Files under `spec/` ending in `_spec.lua` are auto-discovered.
- Use `spec_support.factories` to create users/projects/collections
  without hand-writing INSERTs.
- If the spec doesn't touch the DB, put it in `spec/unit/`. If it does,
  put it in `spec/models/` and call `db_helper.truncate_all()` in
  `before_each`.

### Playwright

- Put end-to-end specs in `spec/e2e/`.
- Tag accessibility specs with `@axe` so the dedicated axe job picks
  them up and the main e2e job skips them.
- Prefer small, page-focused specs over large flows — the CI run time
  adds up fast with a real browser in the loop.

## Updating CI

All four jobs spin up their own postgres service container and load
`db/schema.sql` + `db/seeds.sql` before running. If you add a migration,
also re-run the schema dump (see `bin/lapis-migrate`) so CI picks up the
new shape without having to replay history on every run.
