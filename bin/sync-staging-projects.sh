
psql -d snapcloud_staging -f bin/staging-projects.sql > projects_to_sync.txt
rsync -av --files-from=projects_to_sync.txt cloud@snap.berkeley.edu store/
