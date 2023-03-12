package = "snap-cloud"
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
   homepage = "http://snap.berkeley.edu",
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
   "lpeg"
}
build = {
    type = "builtin",
    modules = {}
}
