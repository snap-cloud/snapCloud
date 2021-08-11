#!/bin/bash

# snapCloud install script for macOS
# contributed by Michael Ball

if [[ -z `which brew` ]]; then
    echo 'Please install homebrew before continuing.';
    echo 'Visit brew.sh for instructions.';
    open https://brew.sh;
    exit 1;
fi

if [[ -z `which npm` ]]; then
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
brew install lua@5.1 luarocks postgres pcre

echo 'Installing OpenResty'
brew tap denji/nginx
brew install denji/nginx/openresty

# Need to link openresty to an nginx name for lapis
ln -s /usr/local/opt/openresty/bin/openresty /usr/local/opt/openresty/bin/nginx

echo 'Adding luarocks path info to bashrc'
echo "" >> ~/.bashrc
echo "# Luarocks 3 and Lua 5.1 tools (added by snapCloud)." >> ~/.bashrc
echo $(luarocks path --lua-version 5.1) >> ~/.bashrc

bin/luarocks-install-macos.sh;

# Setup .env with your username.
if [[ -f '.env' ]]; then
    echo "Skipping creating .env. File already exists.";
else
    echo "Creating a .env for local environment customizations";
    sed s/YOUR_USERNAME/$(whoami)/g .env.example > .env;
fi

echo "Prerequisites installed."
echo "Please follow all instructions after 'Setting up the database' in INSTALL.md"
