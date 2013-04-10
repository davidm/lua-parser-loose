DESCRIPTION

  lua_parser_loose

  Demonstrates loose parsing of Lua code,
  as may be useful for code interactively typed into a text editor.
  
  This includes as an example a proof of concept of expanding Lua 5.2
  code to Lua 5.1 code with explicit _ENV variable.  Example:
 
    "function f(_ENV, x) print(x, y)" -->
    "function _ENV.f(_ENV, x) _ENV.print(x, _ENV.y) end"

  Characteristics of this code:
  - Does not construct any AST but rather streams tokens.
    Should be memory and space efficient on large files.
  - Very loose parsing.
    Should work on broken code, such as that being interactively typed into
    a text editor.
  - Loose parsing makes this code somewhat hard to validate its correctness,
    but I think this can be made robust over valid code and behave
    acceptably on invalid code.
    TODO: add tests.
    It would be easier to use the strict Metalua parser, but I don't want to.
  - The parsing code is designed so that parts of it may be reused for other
    purposes in other projects.

STABILITY

  WARNING!!!
  Experimental code.  Proof of concept.  Not at all well tested currently.
  Fix the code if you want to use in production.

DEPENDENCIES/INSTALLATION
   
  Requires Lua libraries in the Metalua "refactoring" branch (2013-04-09).
  To obtain this, do this in the root directory of this project:
     git clone -b repackaging https://github.com/fab13n/metalua.git
  No need to "make install".
  
  To test, just run "lua example.lua".

COPYRIGHT

  See COPYRIGHT.
  (c) 2013 David Manura.  MIT License (same as Lua 5.1).  2013-04
