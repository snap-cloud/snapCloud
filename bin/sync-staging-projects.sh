<<<<<<< HEAD

psql -d snapcloud_staging -f bin/staging-projects.sql > projects_to_sync.txt
rsync -av --files-from=projects_to_sync.txt cloud@snap.berkeley.edu store/
=======
psql -t -A -d snapcloud_staging -f bin/staging-projects.sql > projects_to_sync.txt
rsync -avhz --files-from=projects_to_sync.txt cloud@snap.berkeley.edu:/mnt/snap_cloud_project_storage/store/ store/
>>>>>>> master
