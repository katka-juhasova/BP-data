#! /usr/bin/lua

require 'Test.More'

plan(3)

local c = require 'CBOR'
local TAG_URI = 32

c.coders['function'] = function (buffer, fct)
    fct(buffer)
end

local function URI (str)
    return function (buffer)
        c.coders.tag(buffer, TAG_URI)
        c.coders.text_string(buffer, str)
    end
end

is( c.encode('STR'):byte(), c.TEXT_STRING(3):byte(), "text string" )
eq_array( {c.encode(URI'STR'):byte(1, 2)}, {0xD8, TAG_URI}, "tag 32" )

local t = { 'http://www.lua.org', URI'http://www.luarocks.org' }
local cbor = c.encode(t)
eq_array( c.decode(cbor), { 'http://www.lua.org', 'http://www.luarocks.org' }, "in a table" )

