#! /usr/bin/lua

require 'Test.More'

plan(50)

local c = require 'CBOR'

is( c.TAG(55799), c.MAGIC, "self-describe CBOR" )

local cbor = c.encode({})
is( c.decode(c.TAG(24) .. cbor), cbor, "encoded CBOR data item" )
is( c.decode(c.TAG(42) .. c.encode'text'), 'text' )
is( c.decode(c.TAG(42) .. c.TAG(42) .. c.encode'text'), 'text' )

is( c.decode(c.encode(1.0/0.0)), 1.0/0.0, "inf" )

is( c.decode(c.encode(-1.0/0.0)), -1.0/0.0, "-inf" )

local nan = c.decode(c.encode(0.0/0.0))
type_ok( nan, 'number', "nan" )
ok( nan ~= nan )

is( c.encode{}:byte(), c.ARRAY(0):byte(), "empty table as array" )

local t = setmetatable( { 'a', 'b', 'c' }, { __index = { [4] = 'd' } } )
is( t[4], 'd' )
t = c.decode(c.encode(t))
is( t[2], 'b' )
is( t[4], nil, "don't follow metatable" )

t = setmetatable( { a = 1, b = 2, c = 3 }, { __index = { d = 4 } } )
is( t.d, 4 )
t = c.decode(c.encode(t))
is( t.b, 2 )
is( t.d, nil, "don't follow metatable" )

t = { 10, 20, nil, 40 }
c.set_array'without_hole'
is( c.encode(t):byte(), c.MAP(3):byte(), "array with hole as map" )
is_deeply( c.decode(c.encode(t)), t )
c.set_array'with_hole'
is( c.encode(t):byte(), c.ARRAY(4):byte(), "array with hole as array" )
is_deeply( c.decode(c.encode(t)), t )
c.set_array'always_as_map'
is( c.encode(t):byte(), c.MAP(3):byte(), "always_as_map" )
is_deeply( c.decode(c.encode(t)), t )

t = {}
c.set_array'without_hole'
is( c.encode(t):byte(), c.ARRAY(0):byte(), "empty table as array" )
c.set_array'with_hole'
is( c.encode(t):byte(), c.ARRAY(0):byte(), "empty table as array" )
c.set_array'always_as_map'
is( c.encode(t):byte(), c.MAP(0):byte(), "empty table as map" )

c.set_float'half'
is( c.encode(65536.1), c.encode(1.0/0.0), "half 65536.1")
is( c.encode(66666.6), c.encode(1.0/0.0), "inf (downcast double -> half)")
is( c.encode(-66666.6), c.encode(-1.0/0.0), "-inf (downcast double -> half)")
is( c.decode(c.encode(66666.6)), 1.0/0.0, "inf (downcast double -> half)")
is( c.decode(c.encode(-66666.6)), -1.0/0.0, "-inf (downcast double -> half)")
is( c.decode(c.encode(7e-6)), 0.0, "epsilon (downcast double -> half)")
is( c.decode(c.encode(-7e-6)), -0.0, "-epsilon (downcast double -> half)")

c.set_float'single'
is( c.encode(3.402824e+38), c.encode(1.0/0.0), "float 3.402824e+38")
is( c.encode(7e42), c.encode(1.0/0.0), "inf (downcast double -> float)")
is( c.encode(-7e42), c.encode(-1.0/0.0), "-inf (downcast double -> float)")
is( c.decode(c.encode(7e42)), 1.0/0.0, "inf (downcast double -> float)")
is( c.decode(c.encode(-7e42)), -1.0/0.0, "-inf (downcast double -> float)")
is( c.decode(c.encode(7e-46)), 0.0, "epsilon (downcast double -> float)")
is( c.decode(c.encode(-7e-46)), -0.0, "-epsilon (downcast double -> float)")

c.set_float'double'
if c.long_double then
    is( c.encode(7e400), c.encode(1.0/0.0), "inf (downcast long double -> double)")
    is( c.encode(-7e400), c.encode(-1.0/0.0), "-inf (downcast long double -> double)")
    is( c.decode(c.encode(7e400)), 1.0/0.0, "inf (downcast long double -> double)")
    is( c.decode(c.encode(-7e400)), -1.0/0.0, "-inf (downcast long double -> double)")
    is( c.decode(c.encode(7e-400)), 0.0, "epsilon (downcast long double -> double)")
    is( c.decode(c.encode(-7e-400)), -0.0, "-epsilon (downcast long double -> double)")
else
    skip("no long double", 6)
end

if c.full64bits then
    is( c.decode(c.encode(0xFFFFFFFFFFFFFFFF)), 0xFFFFFFFFFFFFFFFF, "64 bits")
else
    skip("53 bits", 1)
end

cbor = string.char(0xA2, 0xF7, 0x01, 0x42, 0x69, 0x64, 0x02)
t = c.decode(cbor)
is( t.id, 2, "decode map with nil as table index" )

c.sentinel = {}
t = c.decode(cbor)
is( t[c.sentinel], 1, "decode using a sentinel for nil as table index" )
is( t.id, 2 )

cbor = string.char(0xA2, 0x42, 0x69, 0x64, 0x01, 0x42, 0x69, 0x64, 0x02)
error_like(function ()
               c.decode(cbor)
           end,
           "duplicated keys" )

c.strict = false
lives_ok(function ()
             c.decode(cbor)
         end,
         "duplicated keys" )
