#!/bin/bash

print_ok() {
   echo -e "\033[32m$1\033[0m" 
}

print_error() {
    (>&2 echo -e "\033[37;41mERROR:\033[0m \033[1;31m$1\033[0m");
}

if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root" 1>&2
   exit 1
fi

error() {
    print_error "Failed to perform automatic install."
    print_error "Please follow the instructions for manual install at INSTALL.md."
    exit 1
}

print_ok "Installing lua 5.1..."
apt-get install lua5.1 -y
if [ $? -ne 0 ]; then error; fi

print_ok "Installing libssl..."
apt-get install libssl-dev -y
if [ $? -ne 0 ]; then error; fi

print_ok "Installing luarocks..."
apt-get install luarocks -y
if [ $? -ne 0 ]; then error; fi

print_ok "Installing OpenResty..."
wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
apt-get -y install software-properties-common
add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
apt-get update
apt-get install openresty -y
if [ $? -ne 0 ]; then error; fi

print_ok "Installing lua packages..."
luarocks install lapis
luarocks install md5
luarocks install luasec
luarocks install luacrypto
if [ $? -ne 0 ]; then error; fi

print_ok "Installing authbind..."
apt-get install authbind -y
if [ $? -ne 0 ]; then error; fi

print_ok "Installing PostgreSQL..."
apt-get install postgresql postgresql-client -y
if [ $? -ne 0 ]; then error; fi

print_ok "Prerequisites installed."
print_ok "Please follow all instructions after 'Setting up a Lapis project' in INSTALL.md"
