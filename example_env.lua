-- example of adding _ENV. prefix to globals.

package.path = 'metalua/src/?.lua;' .. package.path
local PARSE = require 'lua_parser_loose'


local code = [[
-- this is a comment. local x = y
local s = "this is a string. local x = y"
local x,y = 5
print(x, a.b:b()[a])
-- if/then
if y then
  local z = 1
  print(x,z)
elseif z then
  print()
  print(x, z)
  -- do block
  do
    local z = 1
    print(x,z)
  end
  print(x,z)
  -- for loops
  for i=1,10 do print(i) end
  for k,v in pairs(t) do print(k,v,vv) end
  -- repeat until
  repeat local z = 1 until z == w
  -- while loop
  do do local z while z do local zz zz() end z(zz) end z() end
  local function f(z,w)
    return z+y+a+(function(w) return w^2 end)()
  end
  -- local recursive scoping
  local g = function() return g end
  local function h() return g, h end
  -- function statement
  function C:m(w) return w^2 end
  -- variable scope that starts on next statement.
  local a = a
  local b = a + b
  b = c
  local c = c + (c)(c)(c) c[c]=4
  -- table syntax
  local a2 = {xx = yy + function() xx = yy end; xx = yy}
  local a2 = {{z=z}, z=z}  -- nested
  local a2 = {[xx]=yy}
  -- semicolon
  local a3 = a3 (a3) ; (a3)(a3)
  -- self
  function a.b:c(z) print(self,z,w) end
  -- end of statement
  do local z = ... a = z end  -- with '...'
  do local z = ""  a = z end  -- with string
  do local z = 5   a = z end  -- with number
  print(z) -- ensure still global
else
  print(z)
end
]]

assert(loadstring(code)) -- quick syntax check
PARSE.replace_env(code, io.write)


-- output:
--[[
-- this is a comment. local x = y
local s = "this is a string. local x = y"
local x,y = 5
_ENV.print(x, _ENV.a.b:b()[_ENV.a])
-- if/then
if y then
  local z = 1
  _ENV.print(x,z)
elseif _ENV.z then
  _ENV.print()
  _ENV.print(x, _ENV.z)
  -- do block
  do
    local z = 1
    _ENV.print(x,z)
  end
  _ENV.print(x,_ENV.z)
  -- for loops
  for i=1,10 do _ENV.print(i) end
  for k,v in _ENV.pairs(_ENV.t) do _ENV.print(k,v,_ENV.vv) end
  -- repeat until
  repeat local z = 1 until z == _ENV.w
  -- while loop
  do do local z while z do local zz zz() end z(_ENV.zz) end _ENV.z() end
  local function f(z,w)
    return z+y+_ENV.a+(function(w) return w^2 end)()
  end
  -- local recursive scoping
  local g = function() return _ENV.g end
  local function h() return g, h end
  -- function statement
  function _ENV.C:m(w) return w^2 end
  -- variable scope that starts on next statement.
  local a = _ENV.a
  local b = a + _ENV.b
  b = _ENV.c
  local c = _ENV.c + (_ENV.c)(_ENV.c)(_ENV.c) c[c]=4
  -- table syntax
  local a2 = {xx = _ENV.yy + function() _ENV.xx = _ENV.yy end; xx = _ENV.yy}
  local a2 = {{z=_ENV.z}, z=_ENV.z}  -- nested
  local a2 = {[_ENV.xx]=_ENV.yy}
  -- semicolon
  local a3 = _ENV.a3 (_ENV.a3) ; (a3)(a3)
  -- self
  function a.b:c(z) _ENV.print(self,z,_ENV.w) end
  -- end of statement
  do local z = ... a = z end  -- with '...'
  do local z = ""  a = z end  -- with string
  do local z = 5   a = z end  -- with number
  _ENV.print(_ENV.z) -- ensure still global
else
  _ENV.print(_ENV.z)
end
--]]
