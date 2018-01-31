package = "snap-cloud"
version = "beta-0"
source = {
   url = "http://snap.berkeley.edu"
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
   "md5",
   "lapis",
   "luasec",
   "luacrypto"
}
build = {
    type = "builtin"
}