#! /usr/bin/env bash

# Deploy a copy of snapCloud
pushd ~/snapCloud/
git checkout master
git pull origin master
git submodule update --recursive --remote

# Build community site
pushd site
Snippets/build.sh
popd

# Create a release on GitHub
source .env
deploy_sha=$(git rev-parse HEAD)
# A modified ISO8601 format. GitHub does not support tags
current_time=$(date -u +"%Y-%m-%dT%H-%M-%S")
repo='https://api.github.com/repos/snap-cloud/snapCloud/releases'
# tag non-production releases as 'prerelase'
prelease=$(if [ "$LAPIS_ENVIRONMENT" = 'production' ]; then echo 'false'; else echo 'true'; fi)
curl -X POST -H "Content-Type:application/json" -u cycomachead:$GITHUB_TOKEN $repo -d "{\"tag_name\": \"$current_time\", \"target_commitish\": \"$deploy_sha\", \"prerelease\": $prelease }"

# Mark a deploy in Rollbar
curl -POST --url https://api.rollbar.com/api/1/deploy/ \
    --data "{\"access_token\": \"$ROLLBAR_TOKEN\", \"environment\":\"$LAPIS_ENVIRONMENT\", \"revision\": \"$deploy_sha\"}"

# The cloud user only has the ability to restart this service.
sudo service snapcloud_daemon restart

popd
