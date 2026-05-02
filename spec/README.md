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

# Lua project deps (applies the xml C++14 workaround — see note below)
bin/install-lua-deps.sh

# Lua test tooling — install from /tmp so luarocks.lock doesn't activate
# and try to pull in the full project dep graph for each tool rock.
(cd /tmp && luarocks install --lua-version=5.1 busted luacheck luacov)

# Node + Playwright
npm install
npx playwright install --with-deps chromium
```

#### Why `bin/install-lua-deps.sh`?

The pinned `xml-1.1.3-1` rock ships C++ code that uses pre-C++17 dynamic
exception specifications. On Ubuntu 22.04+ / modern clang, the default
C++17 dialect rejects these:

```
error: ISO C++17 does not allow dynamic exception specifications
```

[`bin/install-lua-deps.sh`](../bin/install-lua-deps.sh) puts a tiny `g++`
wrapper at the front of `PATH` that injects `-std=gnu++14` into every
C++ invocation. This works regardless of build type (luarocks builtin /
make / cmake) because every C++ compile resolves `g++` via `PATH`; pure
C compiles still go through `gcc` and are unaffected. Setting
`CXX`/`CXXFLAGS` env vars *looks* simpler but isn't reliable — `sudo`
strips them, and luarocks's `builtin` build reads `cfg.variables`, not
the live environment. The Makefile's `install` target and the
`install-snapcloud-deps` CI composite action both run this script, so
dev/prod/CI share one workaround.

## Directory layout

```
spec/
├── spec_helper.lua              # env checks, loaded by busted before every spec
├── support/
│   ├── db_helper.lua            # test DB wrapper + TRUNCATE helpers
│   └── factories.lua            # fixture-style record constructors
├── unit/                        # pure-Lua specs, no DB needed
│   ├── util_spec.lua
│   ├── cors_spec.lua
│   └── permissions_spec.lua     # role predicates + visibility rules
├── models/                      # specs that exercise Lapis models against PG
│   └── users_spec.lua
├── e2e/                         # Playwright browser specs
│   ├── support/
│   │   ├── axe.js               # AxeBuilder wrapper honoring data-axe-excluded
│   │   ├── auth.js              # loginAs() / logout() helpers
│   │   └── fixtures.js          # direct DB seeding for users + projects
│   ├── homepage.spec.js
│   ├── accessibility.spec.js    # @axe-tagged WCAG 2.1 AA audits
│   ├── project-visibility.spec.js
│   ├── admin-access.spec.js
│   ├── teacher-access.spec.js
│   └── auth.spec.js             # sign-up + login
└── data/                        # fixture files (see data/README.md)
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

### Seeding users + projects for e2e tests

[`spec/e2e/support/fixtures.js`](e2e/support/fixtures.js) seeds records
directly into `snapcloud_test` via `pg`. Use it whenever you need:

- A user with a specific `role` (admin, moderator, reviewer, etc.).
- A user with `is_teacher = true`.
- A project in a specific `ispublic` / `ispublished` / `deleted` state.

```js
const { seedUser, seedProject, deleteUser } = require('./support/fixtures');
const { loginAs, logout } = require('./support/auth');

test.beforeAll(async () => {
    await seedUser({ username: 'alice', role: 'admin' });
});
test.afterAll(async () => { await deleteUser('alice'); });

test('admins see /ip_admin', async ({ page, context }) => {
    await loginAs(context, 'alice', 'test-password-1');
    const response = await page.goto('/ip_admin');
    expect(response.status()).toBe(200);
});
```

Passwords default to `test-password-1`. `loginAs` performs the same
sha512 client-side hash the real Snap!Cloud JS applies before POSTing
to `/api/v1/users/:username/login`.

## Accessibility exclusions

### `data-axe-excluded="true"`

Some elements can't usefully be audited by axe — typically third-party
iframes or deliberately-decorative fragments. Snap!Cloud uses one
repo-wide convention for these: **any element with the attribute
`data-axe-excluded="true"` is skipped by every axe scan.**

The canonical example is the embedded Snap! editor on the project page
(`views/project.etlua`):

```html
<iframe
    title="project viewer"
    data-axe-excluded="true"
    src="<%= project:url_for('viewer') %>">
</iframe>
```

The helper in [`spec/e2e/support/axe.js`](e2e/support/axe.js) wires this
up automatically:

```js
const { runAxe } = require('./support/axe');
const { seriousViolations } = await runAxe(page);
expect(seriousViolations).toEqual([]);
```

Rules of thumb:

- **Use sparingly.** Every exclusion is a blind spot. Prefer fixing the
  underlying issue.
- **Comment the reason.** Add an HTML comment above the excluded element
  explaining *why* axe can't audit it.
- **Scope to elements, not whole pages.** If the entire page needs
  excluding, that's a sign the page shouldn't be in the a11y spec list
  at all.
- **Review periodically.** `grep -rn 'data-axe-excluded' views/` is the
  canonical list; revisit it when upgrading axe or refactoring a view.

## Updating CI

All four jobs spin up their own postgres service container and load
`db/schema.sql` + `db/seeds.sql` before running. If you add a migration,
also re-run the schema dump (see `bin/lapis-migrate`) so CI picks up the
new shape without having to replay history on every run.
