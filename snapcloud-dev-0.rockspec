package = "snapcloud"
version = "dev-0"
source = {
   url = "git+https://github.com/snap-cloud/snapCloud.git"
}
description = {
   summary = "A Project Server and API for Snap!.",
   detailed = [[
      This is currently in active development.
      Maybe this will say something witty one day.
   ]],
   homepage = "https://snap.berkeley.edu",
   maintainer = "Bernat Romagosa, Michael Ball, Jens Mönig, Brian Harvey, Jadge Hügle",
   license = "AGPL"
}
dependencies = {
   "lua >= 5.1, < 5.2",
   "lapis",
   "luaossl",
   "xml",
   "lua-resty-mail",
   "luasocket",
   "lua-resty-http",
   "lua-cjson",
   "luasec",
   "inspect"
}
build = {
    type = "builtin",
    modules = {}
}
