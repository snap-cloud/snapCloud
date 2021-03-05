#! /usr/bin/env bash

# renew certs using our config.
# Reference material:
# https://dev-notes.eu/2018/05/set-up-an-automatic-letsencrypt-renewal-cronjob/

source /home/cloud/snapCloud/.env
pushd ~/
# /usr/bin/perl -e 'sleep int(rand(3600))' && # DISABLED SLEEP FOR NOW.
certbot renew --config-dir lets-encrypt --logs-dir lets-encrypt --work-dir lets-encrypt --deploy-hook snapCloud/bin/deploy_certs.sh

curl -XPOST https://hooks.slack.com/workflows/T02BLN36L/A01PUMAEUPR/344588914394149899/$SLACK_KEY \
 -H 'Content-Type: application/json' \
 -d "{\"message\":\"Renewed Snap! Certs $LAPIS_ENVIRONMENT\"}"
popd
