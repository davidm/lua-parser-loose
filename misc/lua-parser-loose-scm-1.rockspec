package = "lua-parser-loose"
version = "scm-1"

source = {
  url = "git://github.com/davidm/lua-parser-loose.git",
}

description = {
  summary = "loose parsing of Lua code, ignoring syntax errors",
  detailed = [[
	Does loose parsing of Lua code.
	If the code has syntax errors, the parse does not abort; rather,
	some information (e.g. local and global variable scopes) is still inferred.
	This may be useful for code interactively typed into a text editor.

	Characteristics of this code:
	- Parsing does not construct any AST but rather streams tokens.
	It should be memory efficient on large files.
	It is also pretty fast.
	- Very loose parsing.
	Does not abort on broken code.
	Scopes of local variables are still resolved even if the code is
	not syntactically valid.
	- Above characteristics make it suitable for use in a text editor,
	where code may be interactively typed.
	- Loose parsing makes this code somewhat hard to validate its correctness,
	but tests are performed to verify robustness.
	- The parsing code is designed so that parts of it may be reused for other
	purposes in other projects.
  ]],
  license = "MIT/X11",
  homepage = "https://github.com/davidm/lua-parser-loose"
}

dependencies = {
  "lua >= 5.0",
}

build = {
  type = "none",
  install = {
    lua = {
	["lua_lexer_loose"] = "lib/lua_lexer_loose.lua",
	["lua_parser_loose"] = "lib/lua_parser_loose.lua"
    }
  },
  copy_directories = { "example", "test" }
}
