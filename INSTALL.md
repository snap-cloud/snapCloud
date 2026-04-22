# Snap!Cloud Installation Guide

## Cloning the repository

First, clone the Snap!Cloud, and Snap! repository into a local folder:

```bash
git clone --recursive git@github.com:snap-cloud/snapCloud.git
git clone git@github.com:jmoenig/snap.git
```

**Note:** The `--recursive` flag is important, as it will clone the submodules that Snap!Cloud depends on. If you forget to use it, you can run `git submodule update --init --recursive` after cloning.

You do not need a local Snap! IDE to run the Snap!Cloud, but you may want to have one for testing purposes. If you do not want a local Snap<em>!</em> copy, you can use the [Snap! site](https://snap.berkeley.edu/snap) online, but you will need to change the API URL to a localhost.

### Symlinking Snap! to Snap!Cloud

To make development easier, you can symlink the Snap! repository into the Snap!Cloud directory. This way, any changes you make to the Snap! code will be reflected in the Snap!Cloud environment.

```bash
cd snapCloud
ln -s ../snap snap
```

(We don't want to use submodules, as we want to be able to update the Snap! repo independently of the Snap!Cloud repo.)

## Development

### Steps to look into

When developing on Snap!Cloud on your local machine, the following sections are important:
1. Prereqs
2. Setting up the database
    * The following subsections should be skimmed or read only, no action needed on these:
        * Lapis database configuration
        * Getting Emails (Follow these instructions for a mail server)
        * A Procfile Runner (You will run the commands here at Step 3, when appropriate)
3. Running the Snap!Cloud

The other sections not listed are not needed for development, but may be needed for certain features or deployment.

## Prereqs

For Ubuntu, you can skip this whole section by running the `bin/prereqs.sh` script, that will try to automatically install all dependencies.

**macOS Users**
MacOS users can run `bin/setup-macos`. You will still need to follow all steps after "Setting up a the database" afterwards.
We recommend you use the latest version of `gcc` avaiable.

**Warning for Ubuntu users**
If you are not running an LTS (long term support) Ubuntu release, you will need to look for this line in `bin/prereqs.sh`:

```
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
```

And change `$(lsb_release -sc)` for the latest possible LTS codename that's still compatible with your distro. For example, if you're running Ubuntu 20.10 groovy, you'll need to use `focal`, which is the latest LTS release before groovy.

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

### Note About `git` protocols

Some rocks still use the `git://` protocol, which GitHub no longer accepts.
The 'easy' was to get around this is to use a global git configuration:

```
$ git config --global url."https://github".insteadOf git://github
```

### Lua Dependencies and `luarocks` macOS

`luarocks` will default to lua 5.3, which we do not use. Instead, `bin/luarocks-macos` "wraps" luarocks with our defaults,
and includes the appropriate C/C++ flags so dependencies compile on recent macOS versions.

You can pass all the same commmands to luarocks, e.g.

```
$ bin/luarocks-macos install --only-deps snapcloud-dev-0.rockspec
```

```
# luarocks install --only-deps snapcloud-dev-0.rockspec
```

Using `--only-deps` avoids an unecessary need to clone the repo from GitHub.

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
You should not need to run locally with SSL enabled. However, you may want to do so, if you were testing either the production or staging configurations. In those cases you might want to generate a self-signed certificate so that you can verify SSL works locally.

Heroku has a good guide on [generating self-signed certs][heroku-guide].
(The default configuration is for files named host.cert, and host.key. You can adjust the Heroku commands or rename your files afterwards.)

[heroku-guide]: https://devcenter.heroku.com/articles/ssl-certificate-self

## Setting up the database

### Starting up a local PostgreSql server

Follow instructions [here](https://tableplus.com/blog/2018/10/how-to-start-stop-restart-postgresql-server.html), depending on your operating system.

### Creating a user and a database

First, try running:

```sh
$ bin/lapis-migrate
```

If all goes well, this will create a local database, and run the initial schema load and seeds.

If you are developing locally, you should be able to authenticate if your postgres user matches your user you are using to run the app. Otherwise, you will first need to add a user named `cloud` to both your system and PostgreSQL and create a database named `snapcloud`, owned by that user:

```sh
$ psql postgres

# Enter these in the PSQL command line
> CREATE USER cloud WITH PASSWORD 'snap-cloud-password';
> ALTER ROLE cloud WITH LOGIN;
> CREATE DATABASE snapcloud OWNER cloud;
```

Alternatively, if you are on Linux, you can have postgres become the superuser, but that is not required

```sh
$ sudo -i
# adduser cloud   # } These are inside the Root of Linux, these are not comments
# su - postgres   # } (Note the Root uses the # instead of the $)

# # Then "ctrl D" here (at the same time)

$ psql

# Note: Enter these in the PSQL command line
> CREATE USER cloud WITH PASSWORD 'snap-cloud-password';
> ALTER ROLE cloud WITH LOGIN;
> CREATE DATABASE snapcloud OWNER cloud;
```

### Building the database schema

Continue by logging in as `cloud` and running the provided SQL file in the main Terminal:

```sh
$ psql -U cloud -d snapcloud -a -f db/schema.sql
```

Linux users can run the following to set the "cloud" to create a substitute user (after running `sudo -i`) before running the above:

```sh
# su - cloud
```

You then have to apply the Migration file (called `migrations.lua`) by running the following command, applying changes to your PSQL snapcloud tables:

```sh
$ bin/lapis-migrate
```

If it all goes well, you should now have all tables properly set up. You can make sure it all worked by firing up the PostgreSQL shell and running the `\dt` command, which should print a list of all tables (`projects` and `users`).

### Lapis database configuration

The above username and password are the default values, defined in `config.lua`. You can override those values by defining environment variables, that lapis will read when the app is booted up.

In development, it's completely fine to stick with these provided values. However, on a production server you must create a much stronger password, which should be stored in an environment variable.

## Development Tools
The Snap!Cloud uses the SASS compiler to compile (some) CSS.

All you need to do is run `npm install` or `npm install -g sass`

This compiles `static/scss` to `static/style/compiled/`.

### Getting Emails
The Snap<em>!</em>Cloud sends emails for certain actions, like new user signups and password resets. In order to test those actions, you need an SMTP server.

We've included a configuration to run a local server called [maildev][maildev].

To install maildev, you need node/npm.

Run: (The macOS install script includes this already.)
```sh
$ npm i -g maildev
```

Start maildev by just typing `maildev`:
```sh
$ maildev
```

When you start maildev, all emails sent by the Snap!Cloud will be avaialbe at:
http://localhost:1080

### A Procfile Runner
We've included a Procfile, which declares all the resources needed to run the app, including postgres.

You can use any tool you'd like to run a procfile, but two common ones are [foreman][foreman] or [node-foreman][nf]. These make it really easy to run all the resources:

```sh
$ foreman s[tart] -p 8080 # OR
$ nf start -x 8080
```

You can now point your browser to `http://localhost:8080` (note: `foreman` and `node-forman (nf)` by default goes to 5000 without the `-p` or `-x` port flag).

[foreman]: https://github.com/ddollar/foreman
[nf]: https://github.com/strongloop/node-foreman


### Object Storage (R2 / MinIO)

Project files (`project.xml`, `media.xml`, thumbnails) can be stored in
an S3-compatible object store instead of local disk. In production we
use Cloudflare R2; for local development any S3-compatible server
works — we recommend [MinIO](https://min.io) because it's a single
binary.

The storage layer is **hybrid**: if `S3_ENDPOINT` and `S3_BUCKET` are
set, new writes go to object storage and reads prefer object storage
but fall back to the local `store/` directory for projects that haven't
been migrated yet. That lets you roll out the backend gradually without
a flag-day migration. If the env vars are unset, the app behaves
exactly like before (disk only), which is fine for local dev if you
don't care about exercising the R2 path.

#### Local MinIO

Install MinIO and its client:

```sh
# macOS
$ brew install minio/stable/minio minio/stable/mc

# Linux — see https://min.io/docs/minio/linux/
```

Start MinIO (the provided `Procfile` already includes a `minio:` line,
so `foreman start` will launch it alongside the app). On first run,
create the bucket:

```sh
$ ./bin/setup-minio
```

That script prints a block of environment variables — paste them into
your `.env` file. After restarting the app, saves will land in the
`snapcloud` bucket. Browse the contents at http://localhost:9001 with
the default `minioadmin` / `minioadmin` credentials.

#### Cloudflare R2

In the Cloudflare dashboard, create a bucket and an API token with
"Object Read & Write" permission. Then set:

```sh
export S3_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
export S3_BUCKET=<bucket-name>
export S3_ACCESS_KEY_ID=<token access key>
export S3_SECRET_ACCESS_KEY=<token secret>
export S3_REGION=auto
# Optional: if you've put a custom domain in front of the bucket,
# pre-signed URLs will be rewritten to use it.
# export S3_PUBLIC_HOST=https://images.snap.berkeley.edu
```

#### Backfilling existing projects

Once an S3 backend is configured, existing disk-only projects keep
working but their files aren't yet in S3. Run the async backfill to
copy them over. The endpoint is authenticated with a shared-secret
bearer token (NOT a session cookie), so first set one in the server's
environment and restart:

```sh
export STORAGE_MIGRATION_TOKEN=$(openssl rand -hex 32)
```

Then from anywhere that can reach the server:

```sh
$ MIGRATION_TOKEN=<same value as STORAGE_MIGRATION_TOKEN> \
    HOST=http://localhost:8080 \
    ./bin/migrate-to-r2.sh
```

It repeatedly calls `POST /api/v1/admin/storage/migrate` (with the
token in an `X-Migration-Token` header) in small batches (default 100
projects at a time) and exits when the server reports it's done. Safe
to interrupt and resume — each batch flips
`projects.storage_location` from `'local'` to `'s3'` for the rows it
uploads, and also seeds `project_versions` from the legacy `d-1`/`d-2`
directories. Re-runs skip already-migrated rows. Check progress with:

```sh
$ curl -H "X-Migration-Token: $MIGRATION_TOKEN" \
    $HOST/api/v1/admin/storage/status
```

**Caveat:** a save on a not-yet-migrated project flips it to `'s3'`
on the fly, but that inline path does NOT preserve the project's
existing `d-1`/`d-2` history. For projects where revert-to-last-save
matters, run the bulk backfill BEFORE users start generating new
traffic against the S3 backend.

When the remaining count hits zero, the local `store/` directory is
effectively frozen — writes still fall through to disk as a safety
net until you set `S3_DISK_WRITES=false`. After a bake period you can
flip that off and keep the disk backend on dev machines only.

#### Known R2 / S3 limits worth being aware of

- **Object key length** is capped at 1024 bytes. Our keys look like
  `projects/<id>/20260419T143022123456Z/project.xml` (well under 100).
- **R2 Class A ops** (writes) are billed per op beyond the free tier.
  Each project save emits 3 PUTs (project.xml, media.xml,
  thumbnail.png) and 0 copies — we write to fresh timestamped folders
  rather than overwriting `current/`, so we never pay for `CopyObject`.
- **R2 Class B ops** (reads) are billed likewise. The thumbnail fetch
  path uses a short-lived presigned URL so the browser reads directly
  from R2 — counting against R2 Class B but bypassing the Snap!Cloud
  server entirely.
- **Single-object PUT** is capped at 5 GiB. Project XML and thumbnails
  are orders of magnitude smaller, so we never need multipart upload.
- **LIST** on R2 is strongly consistent, but we still avoid LIST on
  hot paths and use the `project_versions` table as the authoritative
  index. LIST after delete can still be eventually consistent on some
  S3-compatible stores.
- **Presigned URL TTL** caps at 7 days (SigV4). We use
  `S3_PRESIGN_TTL` (default 300s) for thumbnail URLs so an accidental
  share doesn't leak long-lived access.
- **Bucket count per account** on R2 is 1000. We use 1.
- **No native rename/move** — this is why we never touch
  `projects/<id>/current/...` paths: moving objects around would cost
  a PUT + DELETE per file per save. The timestamp-folder layout + a
  pointer column on `projects` avoids this entirely.

Historical versions are kept per
`PREVIOUS_VERSIONS_TO_KEEP` (default 2). Retention logic matches the
old disk scheme: on each save we archive the displaced version and
then rotate out any archive that was written less than
`STABLE_VERSION_AGE_SECONDS` (default 12h) before it — this prevents
rapid edit churn from burning through the slot budget. Both are
tunable via env vars of the same name.

### Updating Dependencies / Lockfile

To regenerate `luarocks.rock`, use the following command:

```
$ bin/luarocks-macos build --only-deps --pin snapcloud-dev-0.rockspec
```

## Production Configuration

### SSL
The production instance needs SSL to run. See [certs/README.md](certs/README.md) for details on configuring SSL certificates.

### Setting Environment Variables

SnapCloud will read variables from a file `.env` which contains contains data specific to that system. It should look something like this:

```sh
export LAPIS_ENVIRONMENT=production
export DATABASE_HOST=127.0.0.1
export DATABASE_PORT=5432
export DATABASE_USERNAME=cloud
export DATABASE_PASSWORD=snap-cloud-password
export DATABASE_NAME=snapcloud
export HOSTNAME=snap.berkeley.edu
```
There are a lot of options defined in `config.lua`. Setting the environment is helpful because you may want to have a "staging" server with a slightly different configuration.

### Giving permissions to use HTTP(S) ports
(This section applies only to Linux machines.)
Authbind allows a user to bind to ports 0-1023. In development, you will likely not need to use authbind as the server defaults to using port 8080 and doesn't need https. However, on the production server, authbind is necessary.

We now need to configure `authbind` so that user `cloud` can start a service over the HTTP and HTTPS ports. To do so, we simply need to create a file and assign its ownership to `cloud`:

```
# touch /etc/authbind/byport/443
# chown cloud:cloud /etc/authbind/byport/443
# chmod +x /etc/authbind/byport/443
# touch /etc/authbind/byport/80
# chown cloud:cloud /etc/authbind/byport/80
# chmod +x /etc/authbind/byport/80
```

## Running the Snap!Cloud

If it all went well, you're now ready to fire up Lapis. While in development, just run this command under your Snap!Cloud local folder.

If you use authbind:
```
$ ./start.sh
```

Otherwise, run Snap!Cloud using the instructions in: "A Procfile Runner"

You will also need to start your Postgres database separately.
When running locally, follow the instructions listed in "Starting up a local PostgreSql server"

## Setting up the Snap!Cloud as a system daemon

We provide a very simple init script that you can use to run the Snap!Cloud as a daemon in your server. You need to edit the `snapcloud_daemon` script so that it starts the cloud under your user first. Find the following line and replace `cloud` by your actual user. If you have followed this guide, this is not necessary.


`runuser -l cloud`

Then use `update-rc.d` to create the necessary symbolic links:

```
$ update-rc.d snapcloud_daemon defaults
```

You can now start and stop the Snap!Cloud by running:

```
$ service snapcloud_daemon [start|stop]
```
### Add sudo access for the `cloud` user

This is done to make it so the cloud user can easily run maintenance scripts.

Add the following line to `/etc/sudoers`

```
cloud        ALL=NOPASSWD: /usr/sbin/service snapcloud_daemon *
```

The `cloud` user may now run `sudo service snapcloud_daemon restart`

### Production Log Rotation

The Snap!Cloud includes a simple logrotation setup that uses the default `logrotate` program. We run this as the `cloud` user, since that is the process that "owns" the log files. The file `bin/logrotate.conf` is a good starting point.

To run it automatically, add the following to the `cloud` user crontab, by running `crontab -e`.

```
0 2 * * * /usr/sbin/logrotate /home/cloud/logrotate.conf --state /home/cloud/logrotate-state
```

This will run the logrotation script at 2AM each night. (You'll want to create the logrotate-state file, and update the paths as necessary.)
