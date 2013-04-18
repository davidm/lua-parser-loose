-- example of module for use under compat_envvar.lua.

local M = {}

local function g(_ENV) print(x) end

function M.f()
  g {print=print, x=math.sqrt(4)}
  _ENV = {print=print, math=math, x=5}
  print(x)
end

return M
