#!/bin/bash

# beetleCloud install script for OS X / macOS
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
brew install openssl lua@5.1 postgres pcre nginx

# Setup openresty
# http://openresty.org/en/installation.html
OR_VER="1.9.15.1"
wget https://openresty.org/download/openresty-${OR_VER}.tar.gz
tar xvf openresty-$OR_VER.tar.gz
cd openresty-$OR_VER/
# OS X specific setup
./configure \
   --with-cc-opt="-I/usr/local/opt/openssl/include/ -I/usr/local/opt/pcre/include/" \
   --with-ld-opt="-L/usr/local/opt/openssl/lib/ -L/usr/local/opt/pcre/lib/" \
   -j8
make
make install
cd ..
# Add to bash_profile
# export PATH=/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:$PATH

# cleanup openresty install
rm openresty-$OR_VER.tar.gz
rm -rf openresty-$OR_VER

# now install lua.
LUA_CMD="lua-5.1"
LUAROCKS_CMD="luarocks-5.1"

# Needed for lapis
OPENSSL_BREW='/usr/local/opt/openssl/'
LUA_ROCKS_SEARCH_DIR='/usr/local/include/openssl'

# needed to install bcrypt dependencies
OPENSSL_FLAGS="LDFLAGS=-L/usr/local/opt/openssl/lib CPPFLAGS=-I/usr/local/opt/openssl/include";

# Link directories for installing lapis
ln -s $OPENSSL_BREW $LUA_ROCKS_SEARCH_DIR

$OPENSSL_FLAGS $LUA_CMD bcrypt xml lapis

# Cleanup
rm $LUA_ROCKS_SEARCH_DIR
