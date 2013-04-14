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

local expected_out = [[
local <<local:x>>,<<local:y>> = # ( ( <<global:x>>
<<local:x>> == 2
do !
  ( local <<local:w>>)
  <<global:print>>(<<local:x>> ;;; <<local:y>> , <<global:z>>,,<<local:w>>)
end
<<global:print>>(<<global:w>>)
]]


local function mark_variables(code, f)
  if f == nil then return PARSE.accumulate(mark_variables, code) end
  PARSE.extract_vars(code, function(op, name, other)
    if op == 'Id' then
      f('<<' .. other ..  ':' .. name .. '>>')
    elseif op == 'Var' then
      f('<<local:' .. name .. '>>')
    else
      f(name)
    end
  end)
end

--local out = mark_variables(code, io.write)
local out = mark_variables(code)

if out ~= expected_out then
  error('not match:\n'..out)
end

print 'DONE'
