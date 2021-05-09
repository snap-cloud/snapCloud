# This script is designed to be run on LOCAL machine.
# It should use a minimal set of bash (currently run on an Synology server.)

curl -XPOST https://hooks.slack.com/workflows/T02BLN36L/A01PUMAEUPR/344588914394149899/$SLACK_KEY \
 -H 'Content-Type: application/json' \
 -d "{\"message\":\"Backup script started. $(date)\"}"

server='backup@cloud.snap.berkeley.edu'
cloud_src="$server:/mnt/snap_cloud_project_storage/"
local_dest='/volume1/snapcloud'

rsync -az -e "ssh -p 22" --backup --backup-dir="rsync_bak_`date '+%F_%H-%M'`" /var/www backup@[nas-ip]:/volume1/Backups/
