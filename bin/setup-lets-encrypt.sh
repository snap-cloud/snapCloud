#! /usr/bin/env bash

# TODO: This script has not been exhaustively tested.

su - cloud
cd snapCloud
source .env
mkdir -p ~/lets-encrypt/renewal-hooks/deploy
config="certs/lets-encrypt.$LAPIS_ENVIRONMENT"
cp -r ${config}/renewal lets-encrypt/
cp deploy-certs ~/lets-encrypt/renewal-hooks/deploy/1-deploy.sh
echo 'certbot configs in place.'

(crontab -l 2>/dev/null; echo "00 02 * * * ~/snapCloud/bin/renew-certs.sh") | crontab -

echo 'Please login to certbot.'
