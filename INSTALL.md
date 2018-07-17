# Snap!Cloud Install Guide

## Cloning the repository

First of all, clone the Snap!Cloud repository into a local folder:

```
$ git clone --recursive https://github.com/bromagosa/snapCloud.git
```

(Use the `--recursive` option so that you can see the Social site and have a working Snap<em>!</em> install.)

## Prereqs

For Debian-based distros, you can skip this whole section by running the `bin/prereqs.sh` script, that will try to automatically install all dependencies. MacOS users can run `bin/setup_osx.sh`. You will still need to follow all steps after "Setting up a the database" afterwards.


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

All Lua dependencies are contained in the rockspec.
```
# luarocks install snap-cloud-beta-0.rockspec
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

#### Getting a self-signed certificate
Currently, Snap!Cloud is configured to expect a certificate file, even while running locally. You can generate a self-signed cert using the `openssl` command. While self-signed certs are not useful for production sites, it will work just fine when testing things.

Heroku has a good guide on [generating self-signed certs][heroku-guide].
(The default configuration is for files named host.cert, and host.key. You can adjust the Heroku commands or rename your files afterwards.)

[heroku-guide]: https://devcenter.heroku.com/articles/ssl-certificate-self

## Setting up the database

### Creating a user and a database

A PostgreSQL script is provided to help you get all tables set up easily. However, you will first need to add a user named `cloud` to both your system and PostgreSQL and create a database named `snapcloud`, owned by that user:

```
# adduser cloud
# su - postgres

$ psql

> CREATE USER cloud WITH PASSWORD 'snap-cloud-password';
> ALTER ROLE cloud WITH LOGIN;
> CREATE DATABASE snapcloud OWNER cloud;
```

### Building the database schema

Continue by logging in as `cloud` and running the provided SQL file:

```
# su - cloud
$ psql -U cloud -d snapcloud -a -f cloud.sql
```

If it all goes well, you should now have all tables properly set up. You can make sure it all worked by firing up the PostgreSQL shell and running the `\dt` command, which should print a list of all tables (`projects` and `users`).

### Lapis database configuration

The above username and password are the default values, defined in `config.lua`. You can override those values by defining environment variables, that lapis will read when the app is booted up.

In development, it's completely fine to stick with these provided values. However, on a production server you must create a much stronger password, which should be stored in an environment variable.


### Getting Emails
The Snap<em>!</em>Cloud sends emails for certain actions, like new user signups and password resets. In order to test those actions, you need an SMTP server.

We've included a configuration to run a local server called [maildev][maildev].

To install maildev, you need node/npm.

Run: (The macOS install script includes this already.)
```
npm i -g maildev
```

When you start maildev, all emails sent by the Snap!Cloud will be avaialbe at:
http://localhost:1080

### A Procfile Runner
We've included a Procfile, which declares all the resources needed to run the app, including postgres.

You can use any tool you'd like to run a procfile, but two common ones are [foreman][foreman] or [node-foreman][nf]. These make it really easy to run all the resources:

```sh
$ foreman s[tart] # OR
$ nf s[tart]
```

You can now point your browser to `http://localhost:8080`.

[foreman]: https://github.com/ddollar/foreman
[nf]: https://github.com/strongloop/node-foreman


## Production Configuration

## SSL
The production instance needs SSL to run. See [certs/README.md](certs/README.md) for details on configuring SSL certificates.

### Setting Environment Variables

SnapCloud will read variables from a file `.env` which contains contains data specific to that system. It should look something like this:

```sh
export LAPIS_ENVIRONMENT=production
export DATABASE_URL=127.0.0.1:5432
export DATABASE_USERNAME=cloud
export DATABASE_PASSWORD=snap-cloud-password
export DATABASE_NAME=snapcloud
export HOSTNAME=cloud.snap.berkeley.edu
```
There are a lot of options defined in `config.lua`. Setting the environment is helpful because you may want to have a "staging" server with a slightly different configuration.

### Giving permissions to use HTTP(S) ports

(Linux) We now need to configure `authbind` so that user `cloud` can start a service over the HTTP and HTTPS ports. To do so, we simply need to create a file and assign its ownership to `cloud`:

```
# touch /etc/authbind/byport/443
# chown cloud:cloud /etc/authbind/byport/443
# chmod +x /etc/authbind/byport/443
# touch /etc/authbind/byport/80
# chown cloud:cloud /etc/authbind/byport/80
# chmod +x /etc/authbind/byport/80
```

## Running the Snap!Cloud

If it all went well, you're now ready to fire up Lapis. While in development, just run this command under your Snap!Cloud local folder, if you use authbind:

```
$ ./start.sh
```
You will also need to start your Postgres database separately.

## Setting up the Snap!Cloud as a system daemon

We provide a very simple init script that you can use to run the Snap!Cloud as a daemon in your server. You need to edit the `snapcloud_daemon` script so that it starts the cloud under your user first. Find the following line and replace [YOUR USERNAME] by your actual user. If you have followed this guide, it should be `cloud`:


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
