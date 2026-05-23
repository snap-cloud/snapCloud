# Snap!Cloud Deployment Guide

This guide covers production-only deployment concerns. For local
development setup see [`INSTALL.md`](./INSTALL.md).

## Snap! checkouts on the server

The production server keeps several independent Snap! checkouts. They are
served from the locations defined in [`nginx.conf.d/snap-ide.conf`](../nginx.conf.d/snap-ide.conf):

| Path on disk            | Served at              | Tracks                                  |
| ----------------------- | ---------------------- | --------------------------------------- |
| `~/snapCloud/snap/`     | `/snap/`               | The latest tagged Snap! release         |
| `~/snap-versions/dev/`  | `/versions/dev/`       | `origin/master` (development version)   |
| `~/snap-versions/previous/` | `/versions/previous/` | A pinned older tag (see `bin/update-snap`) |

`bin/update-snap` is the entry point for refreshing all three: it
`git fetch`es each checkout, switches to the right ref, and then runs
`bin/compress` against the checkout to produce `.gz` siblings of every
text asset.

`bin/deploy` does the equivalent for `~/snapCloud/static/` itself.

## gzip configuration

Gzip is configured **once**, at the `http { }` level in
[`nginx.conf`](../nginx.conf):

```nginx
gzip on;              # on-the-fly compression for dynamic responses
gzip_static on;       # serve a precompressed .gz sibling when present
gzip_min_length 1000; # don't bother for tiny responses
gzip_proxied any;
gzip_vary on;
gzip_comp_level 6;
gzip_types *;
```

Because these directives live at the http level, every server / location
inherits them — including:

- `/snap/` and `/versions/` — Snap! checkouts, pre-compressed by
  `bin/compress`. `gzip_static` serves the `.gz` directly.
- `/static/` — Snap!Cloud's own CSS/JS/SVG, pre-compressed by
  `bin/compress` during `bin/deploy`.
- `/api/v1/` and `@lapisapp` — lapis dynamic responses (JSON, HTML).
  No `.gz` exists, so `gzip on` compresses them on the fly. This
  covers the large JSON payloads (project listings etc.) that can
  exceed 1 MB.
- `/`, `/old_site`, `/js-extensions` — any other static aliases.

### What is NOT pre-compressed

`bin/compress` deliberately skips `.html` files and `sw.js`. The
`/snap/` and `/versions/` locations use `sub_filter <head> $cloud_loc;`
to inject a `<meta name="snap-cloud-domain">` tag at runtime, and
`gzip_static` would serve the .gz before `sub_filter` could touch the
response — silently dropping the substitution. nginx still gzips these
files dynamically via `gzip on`.

### `gzip_static` requirements

`gzip_static` requires the `ngx_http_gzip_static_module`. OpenResty —
which is what `bin/prereqs.sh` installs — ships with it enabled. If you
build nginx from source, pass `--with-http_gzip_static_module`.

## When pre-compression runs

| Trigger             | Compresses                                       |
| ------------------- | ------------------------------------------------ |
| `bin/update-snap`   | each of the three Snap! checkouts                |
| `bin/deploy`        | `~/snapCloud/static/`                            |
| git hook (see next) | the checkout the hook is installed in           |

`bin/compress` is idempotent — it only re-gzips a file whose source is
newer than the existing `.gz`. Re-running it costs ~nothing.

## Git hooks for automatic compression

`bin/update-snap` already pre-compresses each Snap! checkout when it
runs. For deployments that pull Snap! changes outside of `update-snap`
(e.g. a `git pull` you run by hand, or a webhook-driven update),
install a `post-merge` / `post-checkout` hook in each Snap! checkout
so compression always stays in sync with the source files.

### Installing the hook

Run the following **once per checkout** on the server:

```bash
for repo in \
    ~/snapCloud/snap \
    ~/snap-versions/dev \
    ~/snap-versions/previous; do
    hook="$repo/.git/hooks/post-merge"
    cat > "$hook" <<'EOF'
#!/usr/bin/env bash
# Re-build .gz siblings whenever the working tree changes.
set -e
"$HOME/snapCloud/bin/compress" "$(git rev-parse --show-toplevel)"
EOF
    chmod +x "$hook"
    # `git checkout` (used by update-snap and manual switches) fires
    # post-checkout, not post-merge — symlink the two so both trigger.
    ln -sf post-merge "$repo/.git/hooks/post-checkout"
done
```

Notes:

- The hook body is identical for every checkout, so it's safe to copy
  and to re-install if any checkout gets reset.
- `bin/compress` is idempotent, so leaving the hook installed costs
  nothing.
- The `post-checkout` symlink covers `bin/update-snap`, which uses
  `git checkout <ref>` rather than `git merge`. If your workflow also
  uses `git rebase`, add a `post-rewrite` symlink the same way.
- `*.gz` is in the Snap! repo's `.gitignore`, so the generated files
  never show up in `git status`.

### A matching hook for snapCloud itself

If you want `~/snapCloud/static/` to recompress whenever snapCloud
itself updates (rather than only on `bin/deploy`), install the same
hook in `~/snapCloud/`:

```bash
hook=~/snapCloud/.git/hooks/post-merge
cat > "$hook" <<'EOF'
#!/usr/bin/env bash
set -e
"$HOME/snapCloud/bin/compress" "$HOME/snapCloud/static"
EOF
chmod +x "$hook"
ln -sf post-merge ~/snapCloud/.git/hooks/post-checkout
```

### Alternative: `post-receive` for push-to-deploy setups

If a checkout receives pushes directly (i.e. it has its own bare repo
upstream on the server), install a `post-receive` hook on the bare
repo's side instead. It needs to find the work tree for the checkout:

```bash
#!/usr/bin/env bash
set -e
"$HOME/snapCloud/bin/compress" /path/to/checkout
```

Save as `<bare-repo>/hooks/post-receive` and `chmod +x` it.

## Verifying compression is live

After a deploy, sanity-check that nginx is actually serving the
pre-compressed bytes:

```bash
curl -sI -H 'Accept-Encoding: gzip' https://snap.berkeley.edu/snap/src/morphic.js \
    | grep -i 'content-encoding\|content-length'
```

You should see `content-encoding: gzip` and a `content-length` close to
the on-disk size of `src/morphic.js.gz` (much smaller than the
uncompressed `.js`). If the length matches the uncompressed source,
`gzip_static` did not find the `.gz` — re-run `bin/update-snap` (for a
Snap! checkout) or `bin/compress ~/snapCloud/static` (for snapCloud)
to regenerate.

For lapis API responses, expect `content-encoding: gzip` but no
`content-length` (responses are chunked):

```bash
curl -sI -H 'Accept-Encoding: gzip' https://snap.berkeley.edu/api/v1/projects \
    | grep -i 'content-encoding\|transfer-encoding'
```
