package = "snap-cloud"
version = "beta-0"
source = {
   url = "git://github.com/bromagosa/snapCloud.git"
}
description = {
   summary = "A Project Server and API for Snap!.",
   detailed = [[
      This is currently in active development.
      Maybe this will say something witty one day.
   ]],
   homepage = "http://snap.berkeley.edu",
   license = "AGPL"
}
dependencies = {
   "lua >= 5.1, < 5.2",
   "lapis >= 1.9.0",
   "luaossl",
   "xml",
   "lua-resty-mail",
   "luasocket",
   "lua-resty-http",
   "lua-cjson",
   "luasec"
}
build = {
    type = "builtin",

    modules = {}
}
