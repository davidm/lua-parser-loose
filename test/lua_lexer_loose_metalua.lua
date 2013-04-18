--[[
 lua_lexer_loose_metalua.lua
 Wrapper around the Metalua lexer, which provides
 the same interface as lua_lexer_loose.lua.
 This is slower, but speed improves some by disabling `checks` in lexer.lua.
 Also, this lexer raises on error.
  (c) 2013 David Manura. MIT License.
--]]

local M = {}
local LEX  = require 'metalua.compiler.parser.lexer'
local Stream = {}
Stream.__index = Stream
function Stream:next()
  local tok = self.lx:next()
  if type(tok.lineinfo) == 'table' then tok.lineinfo = tok.lineinfo.first.offset end
  return tok
end
function Stream:peek()
  local tok = self.lx:peek()
  return {tag=tok.tag, tok[1], lineinfo=tok.lineinfo.first.offset}
end
function M.lex(code, f)
  local lx = LEX.lexer:newstream(code)
  while 1 do
    local tok = lx:next()
    if tok.tag == 'Eof' then break end
    f(tok.tag, tok[1], tok.lineinfo.first.offset)
  end
end
function M.lexc(code)
  local lx = LEX.lexer:newstream(code)
  return setmetatable({lx=lx}, Stream)
end

return M


