#! /usr/bin/env bash

# TODO: This script has not been exhaustively tested.

su - cloud
cd snapCloud
source .env
config="certs/lets-encrypt.$LAPIS_ENVIRONMENT"
cp -r ${config}/renewal ~/lets-encrypt/
# The deploy hook is passed by bin/renew-certs (--deploy-hook bin/deploy-certs).
# Don't copy it into ~/lets-encrypt/renewal-hooks/ too, or it runs twice per renewal.
echo 'certbot configs in place.'

(crontab -l 2>/dev/null; echo "00 02 * * * ~/snapCloud/bin/renew-certs") | crontab -

echo 'Please login to certbot.'
