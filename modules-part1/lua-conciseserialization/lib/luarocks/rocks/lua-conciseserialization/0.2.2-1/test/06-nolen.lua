#! /usr/bin/lua

require 'Test.More'

plan(13)

local c = require 'CBOR'

local t = {1, {2, 3}, {4, 5}}
is_deeply(c.decode(c.encode(t)), t, "array")

local s
s = c.OPEN_ARRAY
 .. c.encode(t[1])
 .. c.encode(t[2])
 .. c.OPEN_ARRAY .. c.encode(t[3][1]) .. c.encode(t[3][2]) .. c.BREAK
 .. c.BREAK
is_deeply(c.decode(s), t, "indefinite-length array")

s = c.OPEN_ARRAY
 .. c.encode(t[1])
 .. c.encode(t[2])
 .. c.encode(t[3])
 .. c.BREAK
is_deeply(c.decode(s), t, "indefinite-length array")

t = {Fun=true, Amt=-2}
is_deeply(c.decode(c.encode(t)), t, "map")

s = c.OPEN_MAP
 .. c.encode('Fun') .. c.encode(true)
 .. c.encode('Amt') .. c.encode(-2)
 .. c.BREAK
is_deeply(c.decode(s), t, "indefinite-length map")

s = c.OPEN_MAP
 .. c.encode(nil) .. c.encode(1)
 .. c.encode('id') .. c.encode(2)
 .. c.BREAK
t = c.decode(s)
is(t.id, 2, "decode map with nil as table index")

c.sentinel = {}
t = c.decode(s)
is( t[c.sentinel], 1, "decode using a sentinel for nil as table index" )
is( t.id, 2 )

s = c.OPEN_MAP
 .. c.encode('Fun') .. c.encode(true)
 .. c.encode('Fun') .. c.encode(-2)
 .. c.BREAK
error_like(function ()
               c.decode(s)
           end,
           "duplicated keys" )

c.strict = false
lives_ok(function ()
             c.decode(s)
         end,
         "duplicated keys" )

s = c.OPEN_MAP
 .. c.encode('Fun') .. c.encode(true)
 .. c.encode('Amt')
 .. c.BREAK
error_like(function ()
               c.decode(s)
           end,
           "unexpected BREAK" )

s = c.OPEN_TEXT_STRING
 .. c.encode('strea')
 .. c.encode('ming')
 .. c.BREAK
is(c.decode(s), 'streaming', "indefinite-length string")

s = c.OPEN_TEXT_STRING
 .. c.encode('strea')
 .. c.encode(2)
 .. c.encode('ming')
 .. c.BREAK
error_like(function ()
               c.decode(s)
           end,
           "bad major inside indefinite%-length string" )
