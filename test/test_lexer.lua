-- test of lua_lexer_loose.lua
-- 2013 D.Manura

package.path = '../?.lua;../metalua/src/?.lua;' .. package.path

local LEX = require 'lua_lexer_loose'
-- local LEX = require 'lua_lexer_loose_metalua' -- warning: tests fail

local function split(code)
  local ts = {}
  LEX.lex(code, function(tag, name, pos)
    ts[#ts+1] = tag..'('..name..')'
  end)
  return table.concat(ts, '')
end

local function checkeq(a,b)
  if a ~= b then error('not equal:\n['..tostring(a)..']\n['..tostring(b)..']', 2) end
end

-- trivial whitespace
checkeq(split[[]], [[]])
checkeq(split[[ ]], [[]])
checkeq(split" \t\n\f\r", [[]])
checkeq(split" 1 ", [[Number(1)]])
checkeq(split" \n1 \n", [[Number(1)]])

-- simple
checkeq(split[[1+2]], [[Number(1)Keyword(+)Number(2)]])
checkeq(split[[ 1 + 2 ]], [[Number(1)Keyword(+)Number(2)]])

-- shebang
checkeq(split"#\n1", [[Number(1)]])
checkeq(split"#", [[]])
checkeq(split"#!", [[]])
checkeq(split"#!\n", [[]])
checkeq(split"#!ab\n1", [[Number(1)]])

-- string
checkeq(split[===[
  "" "ab" "\""
  '' 'ab' '\''
  [[]] [[ab]] [[ []"'\n.
  ]]
  [==[[ [] ]]==]
]===],
  [===[String("")String("ab")String("\"")]===]..
  [===[String('')String('ab')String('\'')]===]..
  [===[String([[]])String([[ab]])String([[ []"'\n.
  ]])]===]..
  [===[String([==[[ [] ]]==])]===]
)

-- comment
checkeq(split[===[
--
a
--ab
--[[b]]c
--"c"d
e--[[a
b]]c
]===], [===[Comment(--
)Id(a)Comment(--ab
)Comment(--[[b]])Id(c)Comment(--"c"d
)Id(e)Comment(--[[a
b]])Id(c)]===]
)

-- identifiers and keywords
checkeq(split[[
  and       break     do        else      elseif
  end       false     for       function  if
  in        local     nil       not       or
  repeat    return    then      true      until     while
  a A _ _aA0 AND a.b
]],
  [[Keyword(and)Keyword(break)Keyword(do)Keyword(else)Keyword(elseif)]]..
  [[Keyword(end)Keyword(false)Keyword(for)Keyword(function)Keyword(if)]]..
  [[Keyword(in)Keyword(local)Keyword(nil)Keyword(not)Keyword(or)]]..
  [[Keyword(repeat)Keyword(return)Keyword(then)Keyword(true)Keyword(until)Keyword(while)]]..
  [[Id(a)Id(A)Id(_)Id(_aA0)Id(AND)Id(a)Keyword(.)Id(b)]]
)
checkeq(split[[goto]], [[Id(goto)]]) --IMPROVE?  Lua 5.2 keyword

-- numbers
checkeq(split[[
  0 9 0012 0zZ_
  -1
  0x 0xF 0Xf 0xfg_
  11. .11 0.11 1.2.3
  1.23e 1.23e10 1.23e-10 1.23E+10 1.23e+10zZ_
]],
  [[Number(0)Number(9)Number(0012)Unknown(0zZ_)]]..
  [[Keyword(-)Number(1)]].. --OK? Metalua does this
  [[Unknown(0x)Number(0xF)Number(0Xf)Unknown(0xfg_)]]..
  [[Number(11.)Number(.11)Number(0.11)Unknown(1.2.3)]]..
  [[Unknown(1.23e)Number(1.23e10)Number(1.23e-10)Number(1.23E+10)Unknown(1.23e+10zZ_)]]
)
--TODO: Lua 5.2 hex floats

print 'OK'
