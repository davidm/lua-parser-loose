--[[
 lua_parser_loose.lua.
 Loose parsing of Lua code.  See README.
 (c) 2013 David Manura. MIT License.
--]]

local PARSE = {}

local LEX = require 'lua_lexer_loose'
--local LEX = require 'lua_lexer_loose_metalua'



local function warn(message, position)
  io.stderr:write('WARNING: ', tostring(position), ': ', message, '\n')
end

--[[
 Loose parser.

 lx - lexer stream of Lua tokens.
 f(event...) - callback function to send events to.

 Events generated:
   'Var', name, lineinfo - variable declaration that immediately comes into scope.
   'VarSelf', name, lineinfo - same as 'Var' but for implicit 'self' parameter
     in method definitions.  lineinfo is zero-width space after '('
   'VarNext', name, lineinfo - variable definition that comes into scope
     upon next statement.
   'VarInside', name, lineinfo - variable definition that comes into scope
     inside following block.  Used for control variables in 'for' statements.
   'Id', name, lineinfo - reference to variable.
   'String', name - string or table field
   'Scope', opt - beginning of scope block
   'Endscope', nil, lineinfo - end of scope block
--]]
function PARSE.parse_scope(lx, f)
  local cprev = {tag='Eof'}
  
  -- stack of scopes.
  local scopes = {{}}
  
  local function scope_begin(opt)
    scopes[#scopes+1] = {}
    f('Scope', opt)
  end
  local function scope_end(lineinfo)
    if #scopes <= 1 then
      warn("'end' without opening block", lineinfo)
    else
      table.remove(scopes)
    end
    f('Endscope', nil, lineinfo)
  end
  
  local function parse_function_list(has_self)
    local c = lx:next(); assert(c[1] == '(')
    if has_self then
      local lineinfo = {c.lineinfo+1} -- zero size
      f('VarSelf', 'self', lineinfo)
    end
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
    --print('DEBUG', c.lineinfo)

    -- Detect end of previous statement
    if c.tag == 'Keyword' and (
       c[1] == 'break' or c[1] == 'goto' or c[1] == 'do' or c[1] == 'while' or
       c[1] == 'repeat' or c[1] == 'if' or c[1] == 'for' or c[1] == 'function' and lx:peek().tag == 'Id' or
       c[1] == 'local' or c[1] == ';' or c[1] == 'until' or c[1] == 'return' or c[1] == 'end') or
       c.tag == 'Id' and
           (cprev.tag == 'Id' or
            cprev.tag == 'Keyword' and
               (cprev[1] == ']' or cprev[1] == ')' or cprev[1] == '}' or
                cprev[1] == '...' or cprev[1] == 'end' or
                cprev[1] == 'true' or cprev[1] == 'false' or
                cprev[1] == 'nil') or
            cprev.tag == 'Number' or cprev.tag == 'String')
    then
      if scopes[#scopes].inside_until then scope_end(c.lineinfo) end
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
          scope_begin()
          parse_function_list()
        else -- function definition statement
          c = lx:next(); assert(c.tag == 'Id')
          f('Id', c[1], c.lineinfo)
          local has_self
          while lx:peek()[1] ~= '(' do
            c = lx:next()
            if c.tag == 'Id' then
              f('String', c[1])
            elseif c.tag == 'Keyword' and c[1] == ':' then
              has_self = true
            end
          end
          scope_begin()
          parse_function_list(has_self)
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
         f('VarInside', c[1], c.lineinfo)
         while lx:peek().tag == 'Keyword' and lx:peek()[1] == ',' do
          c = lx:next(); c = lx:next()
          f('VarInside', c[1], c.lineinfo)
        end
      elseif c[1] == 'do' then
        scope_begin('do')
        -- note: do/while/for statement scopes all begin at 'do'.
      elseif c[1] == 'repeat' or c[1] == 'then' then
        scope_begin()
      elseif c[1] == 'end' or c[1] == 'elseif' then
        scope_end(c.lineinfo)
      elseif c[1] == 'else' then
        scope_end(c.lineinfo)
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
  local NEXT = {}   -- unique key
  local INSIDE = {} -- unique key
  local function newscope(vars, opt)
    local newvars = opt=='do' and vars[INSIDE] or {}
    if newvars == vars[INSIDE] then vars[INSIDE] = false end
    newvars[INSIDE]=false
    newvars[NEXT]=false
    return setmetatable(newvars, {__index=vars})
  end
  
  local vars = {}
  vars[NEXT] = false -- vars that come into scope upon next statement
  vars[INSIDE] = false -- vars that come into scope upon entering block
  PARSE.parse_scope(lx, function(op, name, lineinfo)
    --print('DEBUG', op, name)
    local other
    if op == 'Var' or op == 'VarSelf' then
      vars[name] = true
    elseif op == 'VarNext' then
      vars[NEXT] = vars[NEXT] or {}; vars[NEXT][name] = true
    elseif op == 'VarInside' then
      vars[INSIDE] = vars[INSIDE] or {}; vars[INSIDE][name] = true
    elseif op == 'Scope' then
      vars = newscope(vars, name)
    elseif op == 'Endscope' then
      local mt = getmetatable(vars)
      if mt == nil then
        warn("'end' without opening block.", lineinfo)
      else
        vars = mt.__index
      end
    elseif op == 'Id' then
      if vars[name] then other = 'local' else other = 'global' end
    elseif op == 'String' then
      --
    elseif op == 'Statement' then -- beginning of statement
      -- Apply vars that come into scope upon beginning of statement.
      if vars[NEXT] then
        for k,v in pairs(vars[NEXT]) do
          vars[k] = v; vars[NEXT][k] = nil
        end
      end
    else
      assert(false)
    end
    f(op, name, lineinfo, other)
  end)
end

function PARSE.extract_vars(code, f)
  local lx = LEX.lexc(code)
  
  local char0 = 1  -- next char offset to write
  local function gen(char1, nextchar0)
    if char1 > char0 then f('Other', code:sub(char0, char1-1)) end
    char0 = nextchar0
  end
  
  PARSE.parse_scope_resolve(lx, function(op, name, lineinfo, other)
    --print(op, name, lineinfo, other)
    if op == 'Id' then
      gen(lineinfo, lineinfo+#name)
      f('Id', name, other)
    elseif op == 'Var' or op == 'VarNext' or op == 'VarInside' then
      gen(lineinfo, lineinfo+#name)
      f('Var', name)
    end  -- ignore 'VarSelf' and others
  end)
  gen(#code+1, nil)
end

-- helper function.  Can be passed as argument `f` to functions
-- like `replace_env` above to accumulate fragments into a single string.
function PARSE.accumulator()
  local ts = {}
  local mt = {}
  mt.__index = mt
  function mt:__call(s) ts[#ts+1] = s end
  function mt:result() return table.concat(ts) end
  return setmetatable({}, mt)
end

-- helper function
function PARSE.accumulate(g, code)
  local accum = PARSE.accumulator()
  g(code, accum)
  return accum:result()
end

return PARSE
