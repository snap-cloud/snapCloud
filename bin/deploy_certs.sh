 #! /usr/bin/env bash

# MUST USE -L. LetsEncrypt uses symlinks
sourceDir=/home/cloud/lets-encrypt/live/
destDir=/home/cloud/snapCloud/certs/
domain=''
source /home/cloud/snapCloud/.env

if [[ $LAPIS_ENVIRONMENT == 'production' ]]; then
    domain='cloud';
else
    domain='staging';
fi

cp -r -u --verbose -L ${sourceDir}snap-${domain}.cs10.org $destDir
cp -r -u --verbose -L ${sourceDir}${domain}.snap.berkeley.edu $destDir

# restart for nginx to reload the certs.
# TODO can we just "rebuild"?
sudo service snapcloud_daemon restart
