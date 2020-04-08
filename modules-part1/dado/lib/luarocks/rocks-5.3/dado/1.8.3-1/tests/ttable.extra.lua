#!/usr/local/bin/lua

local tostring = tostring
local table = require"table.extra"
local quote = require"dado.sql".quote

-- fullconcat
assert (table.fullconcat{} == "")
assert (table.fullconcat{a=1} == "a=1")
assert (table.fullconcat{a=true} == "a=true")
local s = '{'..table.fullconcat ({a=1,b='2'}, ':', ', ', tostring, quote)..'}'
assert (s == [[{a:1, b:'2'}]] or s == [[{b:'2', a:1}]])
local s = table.fullconcat ({["a'b"]=1, b="q'a"}, " -> ", " AND ", quote, quote)
assert (s == "'a''b' -> 1 AND 'b' -> 'q''a'", ">>"..s.."<<")
local ok, err = pcall (table.pfullconcat, {a = {}})
assert (not ok, err:match"string expected, got table")
local ok, err = pcall (table.pfullconcat, 2)
assert (not ok, err:match"table expected, got number")
io.write"."

-- twostr
local k,v = table.twostr{}
assert (k == "" and v == "")
local k,v = table.twostr{a=1}
assert (k=="a" and v=="1")
local k,v = table.twostr{a=true}
assert (k=="a" and v=="true")
local k,v = table.twostr ({a=1,["q'w"]="a'b",}, "-", "=", quote, quote)
assert ( (k=="'a'-'q''w'" or k=="'q''w'-'a'") and
         (v=="1='a''b'" or v=="'a''b'=1") )
io.write"."

print(' '..table._VERSION.." Ok!")
