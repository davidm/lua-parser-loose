package.path = '../?.lua;../metalua/src/?.lua;' .. package.path
local PARSE = require 'lua_parser_loose'

dofile 'test_lexer.lua'
dofile '../example_env.lua'
dofile '../example_broken.lua'

-- more extensive tests, not normally done automatically
--dofile 'test_luac.lua'
