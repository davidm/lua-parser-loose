--[[
 loose_lua_parser.lua.
 WARNING: experimental code, not well tested.  See README.txt
 (c) 2013 David Manura. MIT License.
--]]

local PARSE = {}

-- Only uses lexer portion of Metalua libraries.
-- Does not user parser or generate AST or code.
local LEX = require 'metalua.compiler.parser.lexer'


--[[
 Loose parser.

 lx - lexer stream of Lua tokens.
 f(event...) - callback function to send events to.

 Events generated:
   'Var', name, lineinfo - variable declaration that immediately comes into scope.
   'VarNext', name, lineinfo - variable deflection that comes into scope upon next statement.
   'Id', name, lineinfo - reference to variable.
   'String', name - string or table field
   'Scope' - beginning of scope block
   'Endscope' - end of scope block
--]]
function PARSE.parse_scope(lx, f)
  local cprev = {tag='Eof'}
  
  -- stack of scopes.
  local scopes = {{}}
  
  local function scope_begin()
    scopes[#scopes+1] = {}
    f('Scope')
  end
  local function scope_end()
    table.remove(scopes)
    f('Endscope')
  end
  
  local function parse_function_list()
    local c = lx:next(); assert(c[1] == '(')
    c = lx:next()
    while c.tag == 'Id' do
      f('Var', c[1], c.lineinfo)
      c= lx:next()
      if c[1] == ',' then c = lx:next() end
    end
  end
  
  while 1 do
    local c = lx:next()
    if c.tag == 'Eof' then break end
    --print('DEBUG', c.lineinfo.first, c.lineinfo.last)

    -- Detect end of previous statement
    if c.tag == 'Keyword' and (
       c[1] == 'break' or c[1] == 'goto' or c[1] == 'do' or c[1] == 'while' or
       c[1] == 'repeat' or c[1] == 'if' or c[1] == 'for' or c[1] == 'function' and lx:peek().tag == 'Id' or
       c[1] == 'local' or c[1] == ';' or c[1] == 'until') or
       c.tag == 'Id' and
           (cprev.tag == 'Id' or
            cprev.tag == 'Keyword' and (cprev[1] == ']' or cprev[1] == ')' or cprev[1] == '}') or
            cprev.tag == 'Number')
    then
      if scopes[#scopes].inside_until then scope_end() end
      f('Statement')
    end
    
    -- Process token(s).
    if c.tag == 'Keyword' then
    
      if c[1] == 'local' and lx:peek().tag == 'Keyword' and lx:peek()[1] == 'function' then
        -- local function
        c = lx:next(); assert(c[1] == 'function')
        c = lx:next()
        f('Var', c[1], c.lineinfo)
        scope_begin()
        parse_function_list()
      elseif c[1] == 'function' then
        if lx:peek()[1] == '(' then -- inline function
          parse_function_list()
          scope_begin()
        else -- function definition statement
          c = lx:next(); assert(c.tag == 'Id')
          f('Id', c[1], c.lineinfo)
          while lx:peek()[1] ~= '(' do
            c = lx:next()
            if c.tag == 'Id' then
              f('String', c[1])
            end
          end
          scope_begin()
          parse_function_list()
        end
      elseif c[1] == 'local' then
        c = lx:next()
        f('VarNext', c[1], c.lineinfo)
        while lx:peek().tag == 'Keyword' and lx:peek()[1] == ',' do
          c = lx:next(); c = lx:next()
          f('VarNext', c[1], c.lineinfo)
        end
      elseif c[1] == 'for' then
         c = lx:next()
         f('Var', c[1], c.lineinfo)
         while lx:peek().tag == 'Keyword' and lx:peek()[1] == ',' do
          c = lx:next(); c = lx:next()
          f('Var', c[1], c.lineinfo)
        end
      elseif c[1] == 'do' or c[1] == 'while' or c[1] == 'repeat' or c[1] == 'then' then
        scope_begin()
      elseif c[1] == 'end' or c[1] == 'elseif' then
        scope_end()
      elseif c[1] == 'else' then
        scope_end()
        scope_begin()
      elseif c[1] == 'until' then
        scopes[#scopes].inside_until = true
      elseif c[1] == '{' then
        scopes[#scopes].inside_table = (scopes[#scopes].inside_table or 0) + 1
      elseif c[1] == '}' then
        local newval = (scopes[#scopes].inside_table or 0) - 1
        newval = newval >= 1 and newval or nil
        scopes[#scopes].inside_table = newval
      end
    elseif c.tag == 'Id' then
      if scopes[#scopes].inside_table and lx:peek().tag == 'Keyword' and lx:peek()[1] == '=' then
        -- table field
        f('String', c[1])
      elseif cprev.tag == 'Keyword' and (cprev[1] == ':' or cprev[1] == '.') then
        f('String', c[1])
      else
        f('Id', c[1], c.lineinfo)
      end
    end
    
    cprev = c
  end
end

--[[
  This is similar to parse_scope but determines if variables are local or global.

  lx - lexer stream of Lua tokens.
  f(event...) - callback function to send events to.
  
  Events generated:
    'Id', name, lineinfo, 'local'|'global'
     (plus all events in parse_scope)
--]]
function PARSE.parse_scope_resolve(lx, f)
  local PENDING = {} -- unique key
  local vars = {}
  vars[PENDING] = {} -- vars that come into scope upon next statement
  PARSE.parse_scope(lx, function(op, name, lineinfo)
    --print('DEBUG', op, name)
    local other
    if op == 'Var' then
      vars[name] = true
    elseif op == 'VarNext' then
      vars[PENDING][name] = true
    elseif op == 'Scope' then
      vars = setmetatable({[PENDING]={}}, {__index=vars})
    elseif op == 'Endscope' then
      vars = getmetatable(vars).__index
    elseif op == 'Id' then
      if vars[name] then other = 'local' else other = 'global' end
    elseif op == 'String' then
      --
    elseif op == 'Statement' then -- beginning of statement
      -- Apply vars that come into scope upon beginning of statement.
      if next(vars[PENDING]) then
        for k,v in pairs(vars[PENDING]) do
          vars[k] = v; vars[PENDING][k] = nil
        end
      end
    else
      assert(false)
    end
    f(op, name, lineinfo, other)
  end)
end

function PARSE.extract_vars(code, f)
  local lx = LEX.lexer:newstream(code)
  
  local char0 = 1  -- next char offset to write
  local function gen(char1, nextchar0)
    if char1 > char0 then f('Other', code:sub(char0, char1-1)) end
    char0 = nextchar0
  end
  
  PARSE.parse_scope_resolve(lx, function(op, name, lineinfo, other)
    --print(op, name, lineinfo, other)
    if op == 'Id' then
      gen(lineinfo.first.offset, lineinfo.last.offset+1)
      f('Id', name, other)
    elseif op == 'Var' or op == 'VarNext' then
      gen(lineinfo.first.offset, lineinfo.last.offset+1)
      f('Var', name)
    end
  end)
  gen(#code+1, nil)
end

--[[
  Converts 5.2 code to 5.1 style code with explicit _ENV variables.
  Example: "function f(_ENV, x) print(x, y)" -->
            "function _ENV.f(_ENV, x) _ENV.print(x, _ENV.y) end"

  code - string of Lua code.  Assumed to be valid Lua (FIX: 5.1 or 5.2?)
  f(s) - call back function to send chunks of Lua code output to.  Example: io.stdout.
--]]
function PARSE.replace_env(code, f)
  PARSE.extract_vars(code, function(op, name, other)
    if op == 'Id' then
      f(other == 'global' and '_ENV.' .. name or name)
    elseif op == 'Var' or op == 'VarNext' or op == 'Other' then
      f(name)
    end
  end)
end

return PARSE
