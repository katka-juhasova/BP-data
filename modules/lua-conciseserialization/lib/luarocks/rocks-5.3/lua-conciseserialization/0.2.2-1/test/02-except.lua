#! /usr/bin/lua

require 'Test.More'

plan(32)

local c = require 'CBOR'

error_like( function ()
                c.set_string'bad'
            end,
            "bad argument #1 to set_string %(invalid option 'bad'%)" )

error_like( function ()
                c.set_array'bad'
            end,
            "bad argument #1 to set_array %(invalid option 'bad'%)" )

error_like( function ()
                c.set_nil'bad'
            end,
            "bad argument #1 to set_nil %(invalid option 'bad'%)" )

error_like( function ()
                c.set_float'bad'
            end,
            "bad argument #1 to set_float %(invalid option 'bad'%)" )

error_like( function ()
                c.register_tag(2.5, print)
            end,
            "bad argument #1 to register_tag %(positive integer expected, got number%)" )

error_like( function ()
                c.register_tag(42, 'bad')
            end,
            "bad argument #2 to register_tag %(function expected, got string%)" )

error_like( function ()
                c.register_simple(2.5, io.stdin)
            end,
            "bad argument #1 to register_simple %(positive integer expected, got number%)" )

error_like( function ()
                c.ARRAY(2.5)
            end,
            "bad argument #1 to ARRAY %(positive integer expected, got number%)" )

error_like( function ()
                c.MAP'bad'
            end,
            "bad argument #1 to MAP %(positive integer expected, got string%)" )

error_like( function ()
                c.TAG(-2)
            end,
            "bad argument #1 to TAG %(positive integer expected, got number%)" )

error_like( function ()
                c.SIMPLE(-2)
            end,
            "bad argument #1 to SIMPLE %(positive integer expected, got number%)" )

error_like( function ()
                c.SIMPLE(1000)
            end,
            "bad argument #1 to SIMPLE %(out of range%)" )

error_like( function ()
                c.encode( print )
            end,
            "encode 'function' is unimplemented" )

error_like( function ()
                c.encode( coroutine.create(plan) )
            end,
            "encode 'thread' is unimplemented" )

error_like( function ()
                c.encode( io.stdin )
            end,
            "encode 'userdata' is unimplemented" )

error_like( function ()
                local a = {}
                a.foo = a
                c.encode( a )
            end,
            "stack overflow",   -- from Lua interpreter
            "direct cycle" )

error_like( function ()
                local a = {}
                local b = {}
                a.foo = b
                b.foo = a
                c.encode( a )
            end,
            "stack overflow",   -- from Lua interpreter
            "indirect cycle" )

error_like( function ()
                c.decode( {} )
            end,
            "bad argument #1 to decode %(string expected, got table%)" )

error_like( function ()
                c.decode(string.char(0x1C))
            end,
            "decode '0x1c' is unimplemented" )

is( c.decode(c.encode("text")), "text" )

error_like( function ()
                c.decode(c.encode("text"):sub(1, -2))
            end,
            "missing bytes" )

error_like( function ()
                c.decode(c.encode("text") .. "more")
            end,
            "extra bytes" )

error_like( function ()
                c.decode(c.encode("text") .. "1")
            end,
            "extra bytes" )

error_like( function ()
                c.decoder( false )
            end,
            "bad argument #1 to decoder %(string or function expected, got boolean%)" )

error_like( function ()
                c.decoder( {} )
            end,
            "bad argument #1 to decoder %(string or function expected, got table%)" )

for _, val in c.decoder(string.rep(c.encode("text"), 2)) do
    is( val, "text" )
end

error_like( function ()
                for _, val in c.decoder(string.rep(c.encode("text"), 2):sub(1, -2)) do
                    is( val, "text" )
                end
            end,
            "missing bytes" )

if utf8 then
    error_like( function ()
                    c.decode("\x61\xBB")
                end,
                "invalid UTF%-8 string" )

    c.strict = false
    is( c.decode("\x61\xBB"), "\xBB", "invalid utf8" )
else
    skip("no utf8", 2)
end

lives_ok( function ()
                for _ in ipairs(c.coders) do end
          end,
          "cannot iterate packers" )
