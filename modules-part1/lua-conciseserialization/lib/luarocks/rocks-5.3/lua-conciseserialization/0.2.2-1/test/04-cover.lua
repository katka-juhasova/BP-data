#! /usr/bin/lua

require 'Test.More'

plan(35)

local c = require 'CBOR'

is( c.decode(c.encode(true)), true, "true" )
is( c.decode(c.encode(false)), false, "false" )

is( c.decode(c.SIMPLE(20)), false, "false" )
is( c.decode(c.SIMPLE(21)), true, "true" )
is( c.decode(c.SIMPLE(22)), nil, "null" )
is( c.decode(c.SIMPLE(23)), nil, "undef" )
is( c.decode(c.SIMPLE(2)), 2, "simple 2" )
is( c.decode(c.SIMPLE(42)), 42, "simple 42" )

c.set_nil'null'
is( c.decode(c.encode(nil)), nil, "nil" )

c.set_float'single'
local nan = c.decode(c.encode(0/0))
type_ok( nan, 'number', "nan" )
ok( nan ~= nan )
is( c.decode(c.encode(3.140625)), 3.140625, "3.140625" )
is( c.decode(c.encode(-2)), -2, "neg -2" )
is( c.decode(c.encode(42)), 42, "pos 42" )

c.set_float'half'
nan = c.decode(c.encode(0/0))
type_ok( nan, 'number', "nan" )
ok( nan ~= nan )
is( c.decode(c.encode(3.125)), 3.125, "3.125" )
is( c.decode(c.encode(-2)), -2, "neg -2" )
is( c.decode(c.encode(42)), 42, "pos 42" )

c.set_string'text_string'
local s = string.rep('x', 2^3)
is( c.decode(c.encode(s)), s, "#s 2^3" )
s = string.rep('x', 2^7)
is( c.decode(c.encode(s)), s, "#s 2^7" )
s = string.rep('x', 2^11)
is( c.decode(c.encode(s)), s, "#s 2^11" )
s = string.rep('x', 2^19)
is( c.decode(c.encode(s)), s, "#s 2^19" )

c.set_string'byte_string'
s = string.rep('x', 2^3)
is( c.decode(c.encode(s)), s, "#s 2^3" )
s = string.rep('x', 2^5)
is( c.decode(c.encode(s)), s, "#s 2^5" )
s = string.rep('x', 2^11)
is( c.decode(c.encode(s)), s, "#s 2^11" )
s = string.rep('x', 2^19)
is( c.decode(c.encode(s)), s, "#s 2^19" )

local t = { string.rep('x', 2^3):byte(1, -1) }
is_deeply( c.decode(c.encode(t)), t, "#t 2^3" )
t = { string.rep('x', 2^9):byte(1, -1) }
is_deeply( c.decode(c.encode(t)), t, "#t 2^9" )
while #t < 2^17 do t[#t+1] = 'x' end
is_deeply( c.decode(c.encode(t)), t, "#t 2^17" )

local h = {}
for i = 1, 2^3 do h[10*i] = 'x' end
is_deeply( c.decode(c.encode(h)), h, "#h 2^3" )
h = {}
for i = 1, 2^9 do h[10*i] = 'x' end
is_deeply( c.decode(c.encode(h)), h, "#h 2^9" )
for i = 1, 2^17 do h[10*i] = 'x' end
is_deeply( c.decode(c.encode(h)), h, "#h 2^17" )

if utf8 then
    c.set_string'check_utf8'
    is( c.encode("\x4F"):byte(), c.TEXT_STRING(1):byte(), "text" )
    is( c.encode("\xFF"):byte(), c.BYTE_STRING(1):byte(), "byte" )
else
    skip("no utf8", 2)
end
