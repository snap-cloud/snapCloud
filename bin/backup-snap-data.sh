# This script is designed to be run on LOCAL machine.
# It should use a minimal set of bash (currently run on an Synology server.)

curl -XPOST https://hooks.slack.com/workflows/T02BLN36L/A01PUMAEUPR/344588914394149899/$SLACK_KEY \
 -H 'Content-Type: application/json' \
 -d "{\"message\":\"Backup script started. $(date)\"}"

server='snap.berkeley.edu'
# New prod (2026-10 cutover) mounts the volume at snap-cloud-project-storage
# (hyphens); old prod used snap_cloud_project_storage (underscores).
cloud_src="$server:/mnt/snap-cloud-project-storage/store/"
local_dest='/Volumes/Media/snapcloud/'

rsync -az --progress -e "ssh -p 22" --backup --backup-dir="rsync_bak_`date '+%F_%H-%M'`" $cloud_src $local_dest

curl -XPOST https://hooks.slack.com/workflows/T02BLN36L/A01PUMAEUPR/344588914394149899/$SLACK_KEY \
 -H 'Content-Type: application/json' \
 -d "{\"message\":\"Backup script completed. $(date)\"}"
