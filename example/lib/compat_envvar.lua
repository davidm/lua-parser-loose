--[[
 compat_envvar.lua
 Mimics Lua 5.2 _ENV behavior in Lua 5.1.

 Example usage: 
 
   require 'compat_envvar':install_searcher()
   require 'foo'
 
 where foo.lua could be something like
 
   local function g(_ENV) print(x) end
   print(math.sqrt(2))
   g {print=print, x=5}
   _ENV = {print=print, x=4}
   print(x)
 
 (c) 2013 David Manura.  MIT License.
--]]

local M = {_VERSION='0.1.20140417'}

local PARSE = require 'lua_parser_loose'

-- utility functions for files.
-- similar utility functions are in file_slurp.
local function file_exists(file)
  local fh = io.open(file, 'r')
  if fh then fh:close(); return true else return false end
end
local function readfile(path)
  local fh = assert(io.open(path, 'rb'))
  local data = fh:read'*a'
  fh:close()
  return data
end

-- similar to Lua 5.2 package.searchpath.
-- a similar function is defined in penlight pl.utils.
function package_searchpath(name, path)
  local sep = package.config:sub(1,1)
  name = name:gsub('%.', sep)
  for pat in path:gmatch('[^;]+') do
    local file = pat:gsub('?', name)
    if file_exists(file) then return file end
  end
end

--[[
  Converts 5.2 code to 5.1 style code with explicit _ENV variables.
  Example: "function f(_ENV, x) print(x, y)" -->
            "function _ENV.f(_ENV, x) _ENV.print(x, _ENV.y) end"

  code - string of Lua code.  Assumed to be valid Lua (FIX: 5.1 or 5.2?)
  f(s) - call back function to send chunks of Lua code output to.
         Example: io.stdout.  If unspecified, function returns string.
--]]
local function replace_env(code, f)
  if not f then return PARSE.accumulate(replace_env, code) end
  PARSE.extract_vars(code, function(op, name, other)
    if op == 'Id' then
      f(other == 'global' and '_ENV.' .. name or name)
    elseif op == 'Var' or op == 'Other' then
      f(name)
    end
  end)
end

-- partial implementation of Lua 5.2 load supporting _ENV.
-- See the https://github.com/davidm/lua-compat-env for a more complete
-- implementation, though based on setfenv.
function M.load(ld, source, mode, env)
  assert(type(ld)=='string', 'not implemented')
  assert(mode == 't' or mode == nil, 'not implemented')
  env = env or _G
  local code = ld
  local f, err = loadstring(code, source) -- optional syntax check on original
  if not f then return f, err end
  local code = 'local _ENV = ...; return function(...) ' .. code .. '\nend'
  code = replace_env(code) --print(code)
  local f, err = loadstring(code, source)
  if not f then return f, err end
  return f(env)
end

-- Searcher function that loads module from package.path
-- but supports Lua 5.2 style _ENV.
function M.searcher(name)
  local path = package_searchpath(name, package.path)
  if not path then return end
  local code = readfile(path)
  return assert(M.load(code, '@'..path))
end
-- note: preserves line number and source path debug info.

-- install searcher function
local installed
function M.install_searcher()
  if not installed then
    table.insert(package.loaders, 2, M.searcher)
    installed = true
  end
end

return M
