#! /usr/bin/env bash

# copy live files from config to the server
# MUST USE -L. LetsEncrypt uses symlinks
sourceDir=~/lets-encrypt/live/
destDir=~/snapCloud/certs/
source ~/snapCloud/.env

cp -r -u --verbose -L ${sourceDir}snap-${LAPIS_ENVIRONMENT}.cs10.org $destDir
cp -r -u --verbose -L ${sourceDir}${LAPIS_ENVIRONMENT}.snap.berkeley.edu $destDir

# restart for nginx to reload the certs.
# TODO can we just "rebuild"?
sudo service snapcloud_daemon restart

