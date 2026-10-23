#!/usr/bin/env bash
# Copy the project files for ~10k projects (see bin/staging-projects.sql) from
# prod to staging. Run on staging as cloud, from ~/snapCloud, with an SSH agent
# that can log in to prod as cloud (e.g. `ssh -A cloud@staging.snap.berkeley.edu`).

# -X: ignore ~/.psqlrc, so settings like \timing don't add lines to the list.
psql -X -t -A -d snapcloud_staging -f bin/staging-projects.sql > projects_to_sync.txt
# -r is needed: --files-from turns off the recursion that -a normally implies,
# so without it rsync only creates the (empty) project directories.
rsync -rahz --stats --files-from=projects_to_sync.txt \
  snap.berkeley.edu:/mnt/snap_cloud_project_storage/store/ store/
