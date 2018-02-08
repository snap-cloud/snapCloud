# Snap!Cloud

The Snap! Cloud is an API-only adaptation of the [Beetle Cloud](http://github.com/bromagosa/beetleCloud) for Snap<i>!</i> that stores only metadata in a database for reduced query response time, while storing actual contents in disk.

## Third party stuff
### Frameworks and tools
* [Leafo](http://leafo.net/)'s [Lapis](http://leafo.net/lapis/) is the lightweight, fast, powerful and versatile [Lua](http://lua.org) web framework that powers the Snap Cloud - [[ MIT ](https://opensource.org/licenses/MIT)]
* The [PostgreSQL](https://www.postgresql.org/) database holds almost all the data, while the rest is stored to disk. - [[ PostgreSQL license ](https://www.postgresql.org/about/licence/)]

### Lua rocks
* [Kepler Project](http://www.keplerproject.org)'s [MD5](https://luarocks.org/modules/luarocks/md5) module is used for password hashing. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Lubyk](https://github.com/lubyk)'s [XML](https://luarocks.org/modules/luarocks/xml) module is used to parse thumbnails and notes out of projects. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Bruno Silvestre](https://github.com/brunoos)'s [LuaSec](https://luarocks.org/modules/brunoos/luasec) module is used for SSL support. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Michal Kottman](https://github.com/mkottman)'s [LuaCrypto](https://luarocks.org/modules/luarocks/luacrypto) module is the Lua frontend to the OpenSSL library. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Leafo](http://leafo.net/)'s [PgMoon](https://luarocks.org/modules/leafo/pgmoon) module is used to connect to the PostgreSQL database for migrations - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Nick Muerdter](https://github.com/GUI)'s [lua-resty-auto-ssl](https://luarocks.org/modules/gui/lua-resty-auto-ssl) module is used to automatically get and renew SSL certificates from [Let's Encrypt](https://letsencrypt.org/). 

### Did we forget to mention your stuff?
Sorry about that! Please file an issue stating what we forgot, or just send us a pull request modifying this [README](https://github.com/bromagosa/beetleCloud/edit/master/README.md).

### Live instance
The Snap!Cloud backend is currently live at [https://snap-cloud.cs10.org](https://snap-cloud.cs10.org).
