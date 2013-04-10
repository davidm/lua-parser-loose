package.path = 'metalua/src/?.lua;' .. package.path
local PARSE = require 'lua_parser_loose'

dofile 'example_env.lua'
dofile 'example_broken.lua'

error 'FIX: add better tests'
