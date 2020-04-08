#! /usr/bin/lua

require 'Test.More'

plan(3)

local m = require 'CBOR'

local function my_cursor_string (str, i, j)
    return {
        s = str,
        i = i or 1,
        j = j or #str,
        underflow = function ()
            error "missing bytes"
        end,
    }
end

local function my_decode (s, i, j)
    local cursor = my_cursor_string(s, i, j)
    local data = m.decode_cursor(cursor)
    if cursor.i < cursor.j then
        error "extra bytes"
    end
    return data
end

local cbor = m.encode({1, 2, 3})
local s = 'BAR' .. cbor .. 'BAZ'
eq_array( my_decode(s, 4, #s - 3), {1, 2, 3}, "my_decode" )

error_like( function ()
                my_decode(s, 4)
            end,
            "extra bytes" )

error_like( function ()
                my_decode(s, 4, #s - 4)
            end,
            "missing bytes" )
