#!/bin/bash
source .env

# If this is the first run, let's build the Snap! site and link the needed Snap!
# Javascript modules.
if [ ! -f site/www/index.html ]; then
    echo "####################################################"
    echo "First time run. Building the Snap! community site..."
    echo "####################################################"
    (cd site; Snippets/build.sh)
    ln -s snap/src/cloud.js site/www/libs/cloud.js
    ln -s snap/src/sha512.js site/www/libs/sha512.js
fi

authbind --deep lapis server $LAPIS_ENVIRONMENT
