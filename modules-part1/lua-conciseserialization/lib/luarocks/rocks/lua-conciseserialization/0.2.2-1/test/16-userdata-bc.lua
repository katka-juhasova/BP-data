#! /usr/bin/lua

require 'Test.More'

if not pcall(require, 'bc') then
    skip_all 'no bc'
end

plan(3)

local c = require 'CBOR'
local bc = require 'bc'
local TAG_BC = 42
bc.digits(65)
local number = bc.number or bc.new

c.coders.userdata = function (buffer, u)
    if getmetatable(u) == bc then
        c.coders.tag(buffer, TAG_BC)
        c.coders.text_string(buffer, tostring(u))
    else
        error("encode 'userdata' is unimplemented")
    end
end

c.register_tag(TAG_BC, function (data)
    return number(data)
end)

local orig = bc.sqrt(2)
local dest = c.decode(c.encode(orig))
is( dest, orig, "bc" )
nok( rawequal(orig, dest) )

error_like( function ()
                c.encode( io.stdin )
            end,
            "encode 'userdata' is unimplemented" )

