#! /usr/bin/lua

require 'Test.More'

plan(13)

local c1 = require 'CBOR'
package.loaded['CBOR'] = nil     -- hack here
local c2 = require 'CBOR'

isnt( c1, c2 )

local t1 = { 10, 20, 30, 40, 50 }
is( c1.encode(t1):byte(), c1.ARRAY(5):byte(), "sequence in array" )
is_deeply( c1.decode(c1.encode(t1)), t1 )
local t2 = { 10, 20, nil, 40 }
is( c1.encode(t2):byte(), c1.MAP(3):byte(), "array with hole in map" )
is_deeply( c1.decode(c1.encode(t2)), t2 )

c1.set_array'with_hole'
c2.set_array'always_as_map'

is( c1.encode(t1):byte(), c1.ARRAY(5):byte(), "sequence in array" )
is_deeply( c1.decode(c1.encode(t1)), t1 )
is( c1.encode(t2):byte(), c1.ARRAY(4):byte(), "array with hole in array")
is_deeply( c1.decode(c1.encode(t2)), t2 )

is( c2.encode(t1):byte(), c2.MAP(5):byte(), "sequence in map" )
is_deeply( c1.decode(c1.encode(t1)), t1 )
is( c2.encode(t2):byte(), c2.MAP(3):byte(), "array with hole in map" )
is_deeply( c2.decode(c2.encode(t2)), t2 )

