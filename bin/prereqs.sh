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
apt-get -y install --no-install-recommends wget gnupg ca-certificates
wget -O - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg
codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release`
echo "deb http://openresty.org/package/debian $codename openresty" \
    | tee /etc/apt/sources.list.d/openresty.list
apt-get update
apt-get -y install openresty
if [ $? -ne 0 ]; then error; fi

print_ok "Installing OpenSSL..."
apt-get -y install openssl
if [ $? -ne 0 ]; then error; fi

print_ok "Installing lua packages..."
luarocks install snapcloud-dev-0.rockspec

if [ $? -ne 0 ]; then error; fi

print_ok "Installing authbind..."
apt-get install authbind -y
if [ $? -ne 0 ]; then error; fi

print_ok "Installing PostgreSQL..."
apt-get install postgresql postgresql-client -y
if [ $? -ne 0 ]; then error; fi

print_ok "Prerequisites installed."
print_ok "Please follow all instructions after 'Setting up the database' in INSTALL.md"
