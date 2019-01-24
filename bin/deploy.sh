#! /usr/bin/env bash

# Deploy a copy of snapCloud
cd ~/snapCloud/
git checkout master
git pull origin master
git submodule update --recursive --remote

# Create a release on GitHub
source .env
deploy_sha=$(git show --pretty=%H)
# A modified ISO8601 format. GitHub does not support tags
current_time=$(date -u +"%Y-%m-%dT%H-%M-%S")
repo='https://api.github.com/repos/bromagosa/snapCloud/releases'
# tag staging releases as 'prerelase'
prelease=$(if [ "$LAPIS_ENVIRONMENT" = 'production' ]; then echo 'true'; else echo 'false'; fi)
curl -X POST -H "Content-Type:application/json" -u cycomachead:$GITHUB_TOKEN $repo -d "{\"tag_name\": \"$current_time\", \"target_commitish\": \"$deploy_sha\", \"prerelease\": \"$prelease\"}"

# The cloud user only has the ability to restart this service.
sudo service snapcloud_daemon restart