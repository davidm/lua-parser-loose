--[[
 lua_lexer_loose.lua.
 Loose lexing of Lua code.  See README.
 
 (c) 2013 David Manura. MIT License.
--]]

local M = {}

-- based on LuaBalanced
local function match_string(s, pos)
  pos = pos or 1
  local posa = pos
  local c = s:sub(pos,pos)
  if c == '"' or c == "'" then
    pos = pos + 1
    while 1 do
      pos = s:find("[" .. c .. "\\]", pos)
      if not pos then return nil, posa, 'syntax error' end
      if s:sub(pos,pos) == c then
        local part = s:sub(posa, pos)
        return part, pos + 1
      else
        pos = pos + 2
      end
    end
  else
    local sc = s:match("^%[(=*)%[", pos)
    if sc then
      local _; _, pos = s:find("%]" .. sc .. "%]", pos)
      if not pos then return nil, posa, 'syntax error' end
      local part = s:sub(posa, pos)
      return part, pos + 1
    else
      return nil, pos
    end
  end
end

-- based on LuaBalanced
local function match_comment(s, pos)
  pos = pos or 1
  if s:sub(pos, pos+1) ~= '--' then
    return nil, pos
  end
  pos = pos + 2
  if s:sub(pos,pos) == '[' then
    local partt, post = match_string(s, pos)
    if partt then
      return '--' .. partt, post
    end
  end
  local part; part, pos = s:match('^([^\n]*\n?)()', pos)
  return '--' .. part, pos
end

-- note: matches invalid numbers too
local function match_numberlike(s, pos)
  local a,b = s:match('^(%.?)([0-9])', pos)
  if not a then
    return nil  -- not number
  end
  local tok, more
  if b == '0' then
    tok, more = s:match('^(0[xX][0-9a-fA-F]*)([_g-zG-Z]?)', pos)
    if tok then -- hex
      if #more == 0 and #tok > 2 then return tok end
    end
  end
  if a == '.' then
    tok, more = s:match('^(%.[0-9]+)([a-zA-Z_%.]?)', pos)
  else
    tok, more = s:match('^([0-9]+%.?[0-9]*)([a-zA-Z_%.]?)', pos)
  end
  if more ~= '' then
    if more == 'e' or more == 'E' then  -- exponent
      local tok2, bad = s:match('^([eE][+-]?[0-9]+)([_a-zA-Z]?)', pos + #tok)
      if tok2 and bad == '' then
        return tok..tok2
      else
        local tok2 = assert(s:match('^[eE][+-]?[0-9a-zA-Z_]*', pos + #tok))
        return tok..tok2, 'bad number'
      end
    else
      local tok2 = s:match('^[0-9a-zA-Z_%.]*', pos + #tok)
      return tok..tok2, 'bad number'
    end
  end
  assert(tok)
  return tok 
end
--TODO: Lua 5.2 hex float

local function newset(s)
  local t = {}
  for c in s:gmatch'.' do t[c] = true end
  return t
end
local function qws(s)
  local t = {}
  for k in s:gmatch'%S+' do t[k] = true end
  return t
end

local sym = newset("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
local dig = newset('0123456789')
local dig2 = qws[[.0 .1 .2 .3 .4 .5 .6 .7 .8 .9]]
local op = newset('=~<>.+-*/%^#=<>;:,.{}[]()')
op['=='] = true
op['<='] = true
op['>='] = true
op['~='] = true
op['..'] = true

local is_keyword = qws[[
  and break do else elseif end false for function if
  in local nil not or repeat return
  then true until while]]

function M.lex(code, f)
  local pos = 1
  local tok = code:match('^#[^\n]*\n?', pos) -- shebang
  if tok then
    --f('Shebang', tok, 1)
    pos = pos + #tok
  end
  while pos <= #code do
    local p2, n2, n1 = code:match('^%s*()((%S)%S?)', pos)
    if not p2 then assert(code:sub(pos):match('^%s*$')); break end
    pos = p2
    
    if sym[n1] then
      local tok = code:match('^([_A-Za-z][_A-Za-z0-9]*)', pos)  
      assert(tok)
      if is_keyword[tok] then
        f('Keyword', tok, pos)
      else
        f('Id', tok, pos)
      end
      pos = pos + #tok
    elseif n2 == '--' then
      local tok, pos2 = match_comment(code, pos)
      assert(tok)
      f('Comment', tok, pos)
      pos = pos2
    elseif n1 == '\'' or n1 == '\"' or n2 == '[[' or n2 == '[=' then
      local tok, _pos2 = match_string(code, pos)
      if tok then
        f('String', tok, pos)
      else
        f('Unknown', code:sub(pos), pos) -- unterminated string
      end
      pos = pos + #tok
    elseif dig[n1] or dig2[n2] then
      local tok, err = match_numberlike(code, pos) assert(tok)
      assert(tok)
      if err then f('Unknown', tok)
      else f('Number', tok, pos) end
      pos = pos + #tok
    elseif op[n2] then
      if n2 == '..' and code:match('^%.', pos+2) then
        tok = '...'
      else
        tok = n2
      end
      f('Keyword', tok, pos)
      pos = pos + #tok
    elseif op[n1] then
      local tok = n1
      f('Keyword', tok, pos)
      pos = pos + #tok
    else
      f('Unknown', n1, pos)
      pos = pos + 1
    end
  end
end

local Stream = {}
Stream.__index = Stream
function Stream:next()
  if self._next then
    local _next = self._next
    self._next = nil
    return _next
  else
    self._next = nil
    return self.f()
  end
end
function Stream:peek()
  if self._next then
    return self._next
  else
    local _next = self.f()
    self._next = _next
    return _next
  end
end

function M.lexc(code, f)
  local yield = coroutine.yield
  local f = coroutine.wrap(function()
    M.lex(code, function(tag, name, pos) --print(tag, '['..name..']')
      if tag ~= 'Comment' then
        yield {tag=tag, name, lineinfo=pos}
      end
    end)
    yield {tag='Eof'}
  end)
  return setmetatable({f=f}, Stream)
end

return M
