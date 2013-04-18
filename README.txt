DESCRIPTION

  lua_parser_loose

  Does loose parsing of Lua code.
  If the code has syntax errors, the parse does not abort; rather,
  some information (e.g. local and global variable scopes) is still inferred.
  This may be useful for code interactively typed into a text editor.
  
  This includes as an example of expanding Lua 5.2
  code to Lua 5.1 code with explicit _ENV variables.  Example:
 
    "function f(_ENV, x) print(x, y)" -->
    "function _ENV.f(_ENV, x) _ENV.print(x, _ENV.y) end"

  Characteristics of this code:
  - Does not construct any AST but rather streams tokens.
    Should be memory and space efficient on large files.
  - Very loose parsing.
    Should work on broken code, such as that being interactively typed into
    a text editor.
  - Loose parsing makes this code somewhat hard to validate its correctness,
    but tests are performed to verify robustness.
    An alternative choice would be use to the strict Metalua parser (easier).
  - The parsing code is designed so that parts of it may be reused for other
    purposes in other projects.

  Language notes:
  
  - The deprecated Lua 5.0 "arg" variable representing variable
    arguments (...) in a function is not specially recognized.

STABILITY

  This is fairly well tested, but the code is new and might still have errors.
  Standard tests are performed in "test/test.lua".
  More extensive tests are in "test/test_luac.lua", which validates the
  parser's local/global variable detection against the luac bytecode
  output listings.  test_luac.lua has been performed against the entire
  LuaDist source code repository (about 2700 .lua files), or at least the
  Lua files in it having no syntax errors.
  
DEPENDENCIES/INSTALLATION

  Copy lua_parser_loose.lua and lua_lexer_loose.lua into your Lua path.
  To test, just run "lua test.lua" in the "test" folder.
  
  There are no dependencies.

COPYRIGHT

  See COPYRIGHT.
  (c) 2013 David Manura.  MIT License (same as Lua 5.1).  2013-04
