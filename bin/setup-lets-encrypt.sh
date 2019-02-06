#! /usr/bin/env bash

# TODO: This script has not been exhaustively tested.

su - cloud
cd snapCloud
source .env
mkdir -p ~/lets-encrypt/renewal-hooks/deploy
config="certs/lets-encrypt.$LAPIS_ENVIRONMENT"
cp -r config/renewal lets-encrypt/
cp config/1-deploy.sh ~/lets-encrypt/renewal-hooks/deploy/

echo 'certbot configs in place.'
echo 'Please login to certbot.'