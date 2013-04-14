--[[
 Compare lua_parser_lua against luac output.
 
 Before using this, set the "source_path" variable to whatever
 source you want to scan.
 You can try penlight [1] or the entire LuaDist repo [2].
 
  [1] git clone https://github.com/stevedonovan/Penlight.git
  [2] git clone --recursive https://github.com/LuaDist/Repository.git
  
 These are extensive tests, which rely on luac, find,
 and scanning a lot of code, so you probably don't want
 to invoke this automatically during deployment.
 
 D.Manura, 2013-04.
--]]

package.path = '../?.lua;../metalua/src/?.lua;' .. package.path

local FS = require 'file_slurp'
local LPL = require 'lua_parser_loose'

-- select the directory to scan Lua code in.
--local source_path = arg[1] or 'Penlight/'
--local source_path = arg[1] or 'Repository/'
local source_path = arg[1] or '../'

local function find_lua_files(path)
  local cmd = "find "..path.." -name '*.lua'"
  local text = FS.readfile(cmd, 'p')
  local files = {}
  for name in text:gmatch('%S+') do
    table.insert(files, name)
  end
  return files
end

local function compare_sets(seta, setb)
  local missinga = {}
  local missingb = {}
  for k in pairs(seta) do
    if not setb[k] then missingb[k] = true end
  end
  for k in pairs(setb) do
    if not seta[k] then missinga[k] = true end
  end
  return missinga, missingb
end

-- Extract globals from Lua code string using luac.
local function luac_parse(code)
  FS.writefile('.tmp', code)
  local out = FS.readfile('luac -p -l .tmp', 'p')
  local globals = {}
  for line, op, name in out:gmatch('\n%s*%d+%s+%[(%d+)%]%s+(%S+)%s+[^;\n]*([^\n]*)') do
    name = name:gsub(';%s*', '')
    line = tonumber(line)
    if op == 'GETGLOBAL' or op == 'SETGLOBAL' then
      --print(line, op, name)
      globals[line] = globals[line] or {}
      globals[line][name] = true
    end
  end
  return globals
end

-- Extract globals from Lua code string using lua_parser_loose.
local function lpl_globals(code)
  local globals = {}
  local linenum = 1
  LPL.extract_vars(code, function(op, name, other)
    if op == 'Id' then
      --print('lpl', linenum, name, other)
      if other == 'global' then
        globals[name..':'..linenum] = true
      end
    elseif op == 'Other' then
      for n in name:gmatch'\n' do linenum=linenum+1 end
    end
  end)
  return globals
end

--[[
 Unfortunately, luac SETGLOBAL (or SETTABUP in 5.2) line numbers refer
 to the end of the current statement, not where the variable being set
 actually occurs.  Line numbers may be too high for multi-line assignment
 statements.  The following code tries to correct this.
 However, it isn't 100% perfect.  This fails:
   x = function()  -- SETGLOBAL
     return x  -- GETGLOBAL
   end  -- end of line
--]]
local function luac_fixup_linenumbers(g_luac, g_lpc, luac_linenums)
  local add = {}
  for k in pairs(g_luac) do
    local name, linenum = assert(k:match'^(.*):(%d+)$')
    local prevlinenum = linenum-1
    local found
    while prevlinenum > 0 and not g_luac[name..':'..prevlinenum] do
      local newk = name..':'..prevlinenum
      if g_lpc[newk] then
        add[newk] = true
	--print(k, '->', newk)
        found = true
      end
      prevlinenum = prevlinenum - 1
    end
    --print('-', k, prevlinenum, linenum)
    if found and not g_lpc[k] then g_luac[k] = nil end
  end
  for k in pairs(add) do g_luac[k] = true end
end

local function luac_globals(code)
  local globals = {}
  local linenums = {}
  local globs = luac_parse(code)
  for linenum=1,table.maxn(globs) do
    if globs[linenum] then
      linenums[linenum] = true
      for name in pairs(globs[linenum]) do
        --print('luac',linenum, name)
	globals[name..':'..linenum] = true
      end
    end
  end
  return globals, linenums
end

local function check_file(file)
  local code = FS.readfile(file)
  print(file)
  
  local g_lpl = lpl_globals(code)
  local g_luac, luac_linenums = luac_globals(code)
  luac_fixup_linenumbers(g_luac, g_lpl, luac_linenums)
  local lpl_missing, luac_missing = compare_sets(g_lpl, g_luac)
  if next(lpl_missing) or next(luac_missing) then
    for k in pairs(lpl_missing) do print('lpl missing', k, file) end
    for k in pairs(luac_missing) do print('luac missing', k, file) end
    return false
  else
    return true
  end
end

local files = find_lua_files(source_path)
local ignore = {
  -- luac_fixup_linenumbers fails
  ['Repository/busted/src/output/plain_terminal.lua']=true;
  ['Repository/lanes/tests/assert.lua']=true;
  ['Repository/busted/src/output/utf_terminal.lua']=true;
  ['Repository/busted/src/output/TAP.lua']=true;
  ['Repository/etree/src/etree.lua']=true;
  -- intentionally broken files
  ['Repository/busted/fail_spec/cl_compile_fail.lua']=true;
  ['Repository/diluculum/Tests/SyntaxError.lua']=true;
  ['Repository/lmock/todo.lua']=true;  --?
  ['Repository/ldoc/tests/example/style/simple.lua']=true; -- ?
  -- syntax extensions
  ['Repository/gslshell/igsl.lua']=true;
  ['Repository/gslshell/examples/nlinfit.lua']=true;
  ['Repository/gslshell/examples/ode-example.lua']=true;
  ['Repository/gslshell/tests/ode-test.lua']=true;
  ['Repository/gslshell/tests/nlinfit-test.lua']=true;
  ['Repository/gslshell/tests/ode-example-qdho.lua']=true;
  ['Repository/gslshell/tests/ex-linalg.lua']=true;
}
local num_failures = 0
for _,file in ipairs(files) do
if not ignore[file] then
  local ok = check_file(file)
  if not ok then num_failures = num_failures + 1 end
end end

if num_failures > 0 then
  error(('%d files failed to parse'):format(num_failures))
end

print 'DONE'

