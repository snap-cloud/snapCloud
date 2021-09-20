-- from Leafo's streak.club
-- https://github.com/leafo/streak.club/commit/8a722fc5c2e137c137eec3c9d4d644365fc77763
local app = require("app")
local columnize
columnize = require("lapis.cmd.util").columnize
print(columnize(app, 0, 4, false))
local tuples
do
  local _accum_0 = { }
  local _len_0 = 1
  for k, v in pairs(app.router.named_routes) do
    _accum_0[_len_0] = {
      k,
      v
    }
    _len_0 = _len_0 + 1
  end
  tuples = _accum_0
end
table.sort(tuples, function(a, b)
  return a[1] < b[1]
end)
return print(columnize(tuples, 0, 4, false))
