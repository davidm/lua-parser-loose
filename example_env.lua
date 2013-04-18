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
  do for k,v in k do print(k,v) end k()v() end
  for i = 1,(function() return i end) do i() end -- lambda control
  -- repeat until
  repeat local z = 1 until z == w
  do local z repeat until z end z()
  do repeat repeat local z until z until z end z()
  -- while loop
  do do local z while z do local zz zz() end z(zz) end z() end
  -- function
  local function f(z,w) return z+y+a+(function(w) return w^2 end)() end
  do print(function(z) return z end,z); z() end -- anon
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
  do local z = ... a = z end   -- with '...'
  do local z = ""  a = z end   -- with string
  do local z = 5   a = z end   -- with number
  do local z = false a = z end -- with false
  do local z = true  a = z end -- with true
  do local z = nil   a = z end -- with nil
  do local z = function()end a = z end  -- with 'end'
  print(z) -- ensure still global
else
  print(z)
end
]]

local expected_out = [[
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
  do for k,v in _ENV.k do _ENV.print(k,v) end _ENV.k()_ENV.v() end
  for i = 1,(function() return _ENV.i end) do i() end -- lambda control
  -- repeat until
  repeat local z = 1 until z == _ENV.w
  do local z repeat until z end _ENV.z()
  do repeat repeat local z until z until _ENV.z end _ENV.z()
  -- while loop
  do do local z while z do local zz zz() end z(_ENV.zz) end _ENV.z() end
  -- function
  local function f(z,w) return z+y+_ENV.a+(function(w) return w^2 end)() end
  do _ENV.print(function(z) return z end,_ENV.z); _ENV.z() end -- anon
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
  do local z = ... a = z end   -- with '...'
  do local z = ""  a = z end   -- with string
  do local z = 5   a = z end   -- with number
  do local z = false a = z end -- with false
  do local z = true  a = z end -- with true
  do local z = nil   a = z end -- with nil
  do local z = function()end a = z end  -- with 'end'
  _ENV.print(_ENV.z) -- ensure still global
else
  _ENV.print(_ENV.z)
end
]]

assert(loadstring(code)) -- quick syntax check
--PARSE.replace_env(code, io.write)
local out = PARSE.replace_env(code)

if out ~= expected_out then
  error('not match:\n'..out)
end

print 'OK'
