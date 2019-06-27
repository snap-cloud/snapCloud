#!/bin/bash

# snapCloud install script for OS X / macOS
# contributed by Michael Ball


# Ensure brew is installed.
if [[-z `which brew`]]; then
    echo 'Please install homebrew before continuing.';
    echo 'Visit brew.sh for instructions.';
    exit 1;
fi

if [[-z `which npm`]]; then
    echo 'Skipping installing maildev (an email catcher).'
    echo 'To install maildev, first install node (npm), then do:'
    echo '"npm install -g maildev"'
else
    echo 'Installing maildev...'
    npm install -g maildev
fi


# Install basic dependencies via brew
# Note that we must use lua 5.1, not 5.2 or 5.3
echo 'Installing lua and postgres'
brew install lua@5.1 postgres pcre

echo 'Installing OpenResty'
brew tap denji/nginx
brew install denji/nginx/openresty

# Need to link openresty to an nginx name for lapis
ln -s /usr/local/opt/openresty/bin/openresty /usr/local/opt/openresty/bin/nginx

./luarocks-install-macos.sh
