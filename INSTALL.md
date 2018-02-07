# Snap!Cloud Install Guide

## Cloning the repository

First of all, clone the Snap!Cloud repository into a local folder:

```
$ git clone https://github.com/bromagosa/snapCloud.git
```

## Prereqs

For Debian-based distros, you can skip this whole section by running the prereqs.sh script, that will try to automatically install all dependencies. You will still need to follow all steps after "Setting up the database" afterwards.

### Lua 5.1

Lua is the language that powers the whole Snap!Cloud. Under Debian/Ubuntu, you can install it by means of APT:

```
# apt-get install lua5.1
```

Please note that you need version 5.1 specifically.

### OpenResty

The Snap!Cloud system is built on top of [Lapis](http://leafo.net/lapis/), a server-side Lua (or MoonScript) web framework that runs on [OpenResty](http://openresty.org), a modified version of Nginx. First of all, you need to [download](http://openresty.org/#Download) and install OpenResty by following its [official install guide](http://openresty.org/#Installation).

### Lapis and extra Lua modules

Once OpenResty is ready, installing Lapis is just a matter of asking the LuaRocks module manager to do that for you. In a Debian/Ubuntu system, you can install them via APT:

```
# apt-get install luarocks
```

Additional Lua packages you need for the Snap!Cloud to work properly are the Bcrypt module and the md5 module used for secure password encryption. You can use LuaRocks to install them all as root:

```
# luarocks install lapis
# luarocks install md5
# luarocks install xml
# luarocks install luasec
# luarocks install luacrypto
```

#### Only for the MioSoft Cloud migration

When using the migrate.lua script to import collections exported from the MioSoft Cloud (previous Snap! Cloud), you'll need to also install the following Lua rock:

```
# luarocks install pgmoon

```

### Authbind

In order to serve the cloud over HTTPS, we need the cloud user to have permissions over port 443, for which we're going to be using the `authbind` utility.

```
# apt-get install authbind -y
```

### PostgreSQL

The Snap!Cloud backend uses PostreSQL for storage, so you'll need to install it too. Again, under Debian/Ubuntu this is trivial:

```
# apt-get install postgresql postgresql-client
```

### SSL

To serve the backend over SSL we are making use of the Let's Encrypt API through the [Lua-Resty-AutoSSL](https://github.com/GUI/lua-resty-auto-ssl) package. You will also need to install its dependencies:

```
# apt-get install openssl
```

Once the dependencies are met, you can install the Lua rock:

```
# luarocks install lua-resty-auto-ssl
```

## Setting up the database

### Creating a user and a database

A PostgreSQL script is provided to help you get all tables set up easily. However, you will first need to add a user named `snap` to both your system and PostgreSQL and create a database named `snapcloud`, owned by that user:

```
# adduser snap
# su - postgres

$ psql

> CREATE USER snap WITH PASSWORD 'postgres_password';
> ALTER ROLE snap WITH LOGIN;
> CREATE DATABASE snapcloud OWNER snap;
```

### Building the database schema

Continue by logging in as `snap` and running the provided SQL file:

```
# su - snap
$ psql -U snap -d snapcloud -a -f cloud.sql
```

If it all goes well, you should now have all tables properly set up. You can make sure it all worked by firing up the PostgreSQL shell and running the `\dt` command, which should print a list of all tables (`projects` and `users`).

### Lapis database configuration

Now, rename the `rename_me_to_config.lua` file to `config.lua`, as the filename says, and edit it according to your own setup. The `.gitconfig` file makes sure this file is never pushed to the repository, but you should still be careful to never share it, as it contains the database password and the secret phrase used to hash Lapis sessions.

### Giving permissions to use HTTP(S) ports

We now need to configure authbind so that user `snap` can start a service over the HTTP and HTTPS ports. To do so, we simply need to create a file and assign its ownership to `snap`:

```
# touch /etc/authbind/byport/443
# chown snap:snap /etc/authbind/byport/443
# chmod +x /etc/authbind/byport/443
# touch /etc/authbind/byport/80
# chown snap:snap /etc/authbind/byport/80
# chmod +x /etc/authbind/byport/80
```

## Running the Snap!Cloud

If it all went well, you're now ready to fire up Lapis. While in development, just run this command under your Snap!Cloud local folder:

```
$ ./start.sh
```

You can now point your browser to `https://localhost`.

## Setting up the Snap!Cloud as a system daemon

We provide a very simple init script that you can use to run the Snap!Cloud as a daemon in your server. You need to edit the `snapcloud_daemon` script so that it starts the cloud under your user first. Find the following line and replace [YOUR USERNAME] by your actual user. If you have followed this guide, it should be `snap`:


```
    start-stop-daemon --start --quiet --startas $DAEMON -u [YOUR USERNAME] -- --boot || status =$?
```

Then use `update-rc.d` to create the necessary symbolic links:

```
# update-rc.d snapcloud_daemon defaults
```

You can now start and stop the Snap!Cloud by running:

```
# /etc/init.d/snapcloud_daemon start
```

and

```
# /etc/init.d/snapcloud_daemon stop
```
