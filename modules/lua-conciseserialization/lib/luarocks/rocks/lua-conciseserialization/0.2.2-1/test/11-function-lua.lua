#! /usr/bin/lua

require 'Test.More'

plan(4)

local loadstring = loadstring or load
local c = require 'CBOR'
local TAG_BYTECODE_LUA = 666

c.coders['function'] = function (buffer, fct)
    c.coders.tag(buffer, TAG_BYTECODE_LUA)
    c.coders.byte_string(buffer, assert(string.dump(fct)))
end

c.register_tag(TAG_BYTECODE_LUA, function (data) return assert(loadstring(data)) end)

local function square (n) return n * n end
is( square(2), 4 )
local result = c.decode(c.encode(square))
type_ok( result, 'function' )
nok( rawequal(square, result) )
is( result(3), 9 )

