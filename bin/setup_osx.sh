#!/bin/bash

# snapCloud install script for OS X / macOS
# contributed by Michael Ball


# Ensure brew is installed.
if [[-z `which brew`]]; then
    echo 'Please install homebrew before continuing.';
    echo 'Visit brew.sh for instructions.';
    exit 1;
fi

# Install basic dependencies via brew
# Note that we must use lua 5.1 becaus lapis isn't yet in the 5.2 directory
# on luarocks. (Current brew default is lua 5.2)
brew install lua@5.1 postgres pcre

brew tap denji/nginx
brew install denji/nginx/openresty

# Need to link openresty to an nginx name for lapis
ln -s /usr/local/opt/openresty/bin/openresty /usr/local/opt/openresty/bin/nginx

# now install lua.
LUA_CMD="lua-5.1"
LUAROCKS_CMD="luarocks-5.1"

# Needed for lapis
OPENSSL_BREW='/usr/local/opt/openssl/'

# Link directories for installing lapis
ln -s $OPENSSL_BREW $LUA_ROCKS_SEARCH_DIR

$LUAROCKS_CMD install snap-cloud-beta-0.rockspec # OPENSSL_DIR=$OPENSSL_BREW
