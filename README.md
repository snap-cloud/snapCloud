# Snap!Cloud

The Snap<em>!</em>Cloud is a backend for Snap<i>!</i> that stores only metadata in a database for reduced query response time, while storing actual contents in disk.

## Third party stuff

### Frameworks and tools
* [Leafo](http://leafo.net/)'s [Lapis](http://leafo.net/lapis/) is the lightweight, fast, powerful and versatile [Lua](http://lua.org) web framework that powers the Snap Cloud - [[ MIT ](https://opensource.org/licenses/MIT)]
* The [PostgreSQL](https://www.postgresql.org/) database holds almost all the data, while the rest is stored to disk. - [[ PostgreSQL license ](https://www.postgresql.org/about/licence/)]

### Lua rocks
* [Lubyk](https://github.com/lubyk)'s [XML](https://luarocks.org/modules/luarocks/xml) module is used to parse thumbnails and notes out of projects. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Michal Kottman](https://github.com/mkottman)'s [LuaCrypto](https://luarocks.org/modules/luarocks/luacrypto) module is the Lua frontend to the OpenSSL library. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Leafo](http://leafo.net/)'s [PgMoon](https://luarocks.org/modules/leafo/pgmoon) module is used to connect to the PostgreSQL database for migrations - [[ MIT ](https://opensource.org/licenses/MIT)]

### Frontend Tools
* [Matt Holt](https://github.com/mholt)'s [Papaparse](https://www.papaparse.com) library is used to parse CSV files for bulk account creation. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Eli Grey](https://github.com/eligrey)'s [FileSaver.js](https://github.com/eligrey/FileSaver.js/) library is used to save project files from the project page, and maybe elsewhere - [[ MIT ](https://opensource.org/licenses/MIT)]
* Bootstrap 5, npm

## Installation
See the [INSTALL.md](INSTALL.md) file for installation instructions.

### Live instance
The Snap!Cloud is currently live at [https://snap.berkeley.edu](https://snap.berkeley.edu). See the API description page at [https://snap.berkeley.edu/static/API](https://cloud.snap.berkeley.edu/static/API).

### Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) before sending us any pull requests. Thank you!
