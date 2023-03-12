#! /usr/bin/env bash

# Simple macOS wrapper around `luarocks install` because this
# command is a little too complex to remember.

# for installing with the correct version
LUA_DIR="/usr/local/opt/lua@5.1"

# Needed for lapis
OPENSSL_BREW='/usr/local/opt/openssl/'

echo 'Installing lua dependencies'
gcc_version='gcc-10'
# For some reason luarocks needs both directories specified...
# Set by parameter the Lua version used (currently 5.1)
luarocks install --lua-dir=$LUA_DIR snap-cloud-dev-0.rockspec OPENSSL_DIR=$OPENSSL_BREW CRYPTO_DIR=$OPENSSL_BREW CC=$gcc_version LD=$gcc_version $@
