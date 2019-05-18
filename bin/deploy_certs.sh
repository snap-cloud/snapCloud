#! /usr/bin/env bash

# copy live files from config to the server
# MUST USE -L. LetsEncrypt uses symlinks
sourceDir=/home/cloud/lets-encrypt/live/
destDir=/home/cloud/snapCloud/certs/
source /home/cloud/snapCloud/.env

cp -r -u --verbose -L ${sourceDir}snap-${LAPIS_ENVIRONMENT}.cs10.org $destDir
cp -r -u --verbose -L ${sourceDir}${LAPIS_ENVIRONMENT}.snap.berkeley.edu $destDir

# restart for nginx to reload the certs.
# TODO can we just "rebuild"?
sudo service snapcloud_daemon restart

