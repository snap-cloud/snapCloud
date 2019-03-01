#! /usr/bin/env bash

# copy live files from config to the server
# MUST USE -L. LetsEncrypt uses symlinks
cp -r -u -L ~/lets-encrypt/live/snap-cloud.cs10.org/ ~/snapCloud/certs/snap-cloud.cs10.org
cp -r -u -L ~/lets-encrypt/live/cloud.snap.berkeley.edu/ ~/snapCloud/certs/cloud.snap.berkeley.edu
# restart for nginx to reload the certs.
# TODO can we just "rebuild"?
sudo service snapcloud_daemon restart

