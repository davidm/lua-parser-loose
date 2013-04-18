package.path = '../lib/?.lua;../example/lib/?.lua;../metalua/src/?.lua;' .. package.path
local PARSE = require 'lua_parser_loose'

dofile 'test_lexer.lua'
dofile '../example/env.lua'
dofile '../example/broken.lua'

-- more extensive tests, not normally done automatically
--dofile 'test_luac.lua'
