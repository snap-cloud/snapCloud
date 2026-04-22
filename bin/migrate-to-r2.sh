#!/usr/bin/env bash
# Drive the async backfill of on-disk project files into S3.
#
# Usage:
#   MIGRATION_TOKEN=<STORAGE_MIGRATION_TOKEN value from the server> \
#     HOST=https://snap.berkeley.edu \
#     BATCH=100 \
#     SLEEP=2 \
#     ./bin/migrate-to-r2.sh
#
# Hits /api/v1/admin/storage/migrate in a loop with a bearer token in
# the `X-Migration-Token` header. The endpoint is idempotent: each
# batch flips `projects.storage_location` from 'local' to 's3' for
# the rows it uploaded, so the next call skips them. The loop exits
# when the server reports `done: true`.
#
# Run this BEFORE flipping any clients/editor to depend on S3 reads.
# Saves made after the server starts writing to S3 will flip
# individual projects to s3 on the fly, but their legacy on-disk
# d-1/d-2 archive history isn't preserved through that path — the
# bulk backfill is what seeds `project_versions` from those.

set -euo pipefail

: "${HOST:?set HOST (e.g. http://localhost:8080)}"
: "${MIGRATION_TOKEN:?set MIGRATION_TOKEN (matches STORAGE_MIGRATION_TOKEN)}"
BATCH="${BATCH:-100}"
SLEEP="${SLEEP:-2}"

while :; do
  response=$(
    curl -fsS -X POST \
      -H "X-Migration-Token: $MIGRATION_TOKEN" \
      "$HOST/api/v1/admin/storage/migrate?batch=$BATCH"
  )
  echo "$response"
  done=$(printf '%s' "$response" | sed -n 's/.*"done":[[:space:]]*\([a-z]*\).*/\1/p')
  if [ "$done" = "true" ]; then
    echo "migration complete."
    break
  fi
  sleep "$SLEEP"
done
