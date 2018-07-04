#! /bin/bash

# Sync admin's projects from the main server to a staging server
# This is useful for having real data to test with.
# Run ./copy-admin-projects.sh on the destination machine.

read -r -d '' STATEMENT << SQL
SELECT floor(p.id / 1000) || '/' || p.id AS directory
FROM projects p
JOIN users u ON p.username = u.username
WHERE u.isadmin = true
SQL

su cloud;
project_list='/tmp/project_dirs.txt'
psql -d snapcloud -c "$STATEMENT" -t -o $project_list;

store_dir='/home/cloud/snapCloud/store';

rsync -avhz --recursive \
    --files-from=$project_list root@snap-cloud.cs10.org:$store_dir \
    $store_dir;