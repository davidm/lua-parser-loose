-- performance test

package.path = '../?.lua;../metalua/src/?.lua;' .. package.path

local FS = require 'file_slurp'
local LPL = require 'lua_parser_loose'

local code = FS.readfile(arg[1] or 'Penlight/lua/pl/xml.lua')

for i=1,10 do
  --assert(loadstring(code))
  LPL.extract_vars(code, function(op, name, other)
  --if op == 'Var' then print(name) end
  end)
end
