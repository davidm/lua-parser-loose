-- example of parsing broken Lua code.

package.path = 'metalua/src/?.lua;' .. package.path
local PARSE = require 'lua_parser_loose'

local code = [[
local x,y = # ( ( x
x == 2
do !
  ( local w)
  print(x ;;; y , z,,w)
end
print(w)
]]

PARSE.extract_vars(code, function(op, name, other)
  if op == 'Id' then
    io.write('<<', other, ':', name, '>>')
  elseif op == 'Var' then
    io.write('<<local:', name, '>>')
  else
    io.write(name)
  end
end)


-- output:
--[[
<<local:x>><<local:y>>local x,y = # ( ( <<global:x>>
<<local:x>><<local:w>> == 2
do !
  ( local w)
  <<global:print>>(<<local:x>> ;;; <<local:y>> , <<global:z>>,,<<local:w>>)
end
<<global:print>>(<<global:w>>)
--]]
