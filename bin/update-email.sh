#! /usr/bin/env bash

# Update a user's email address.
# bin/update-email.sh username email@domain.com

psql -e -d snapcloud -c "UPDATE users SET email = '$2' WHERE username = '$1';"
