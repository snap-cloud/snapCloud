# Snap!Cloud Install Guide

## Prereqs

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

Additional Lua packages you need for the Snap!Cloud to work properly are the Bcrypt module, used for secure password encryption, and the XML module, used to parse and build Snap<i>!</i> projects. You can use LuaRocks to install them all as root:

```
# luarocks install lapis
# luarocks install xml
# luarocks install bcrypt
# luarocks install md5
# luarocks install luasec
```

### PostgreSQL

The Snap!Cloud backend uses PostreSQL for storage, so you'll need to install it too. Again, under Debian/Ubuntu this is trivial:

```
# apt-get install postgresql postgresql-client
```

## Cloning the repository and getting Lapis ready

First of all, clone the Snap!Cloud repository into a local folder:

```
$ git clone https://github.com/bromagosa/snapCloud.git
```

Then, just tell Lapis to set up that folder as a Lapis web application:

```
$ cd snapCloud
$ lapis new --lua
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

## Running the Snap!Cloud

If it all went well, you're now ready to fire up Lapis. While in development, just run this command under your Snap!Cloud local folder:

```
$ lapis server
```

You can now point your browser to `http://localhost:8080`.

When deploying it, you'll need to add the `--production` flag to it, and if you're using port 80 you'll need to run Lapis from a user account with permission to do so:

```
$ lapis server --production
```
