#! /usr/bin/lua

require 'Test.More'

if not pcall(require, 'base64') then
    skip_all 'no base64'
end

plan(3)

local c = require 'CBOR'
local b64 = require 'base64'
local TAG_BASE64 = 34

c.coders['function'] = function (buffer, fct)
    fct(buffer)
end

local function BASE64 (str)
    return function (buffer)
        c.coders.tag(buffer, TAG_BASE64)
        c.coders.text_string(buffer, b64.encode(str))
    end
end

c.register_tag(TAG_BASE64, function (str)
    assert(type(str) == 'string', "invalid data item")
    return b64.decode(str)
end)

is( c.encode('STR'):byte(), c.TEXT_STRING(3):byte(), "text string" )
eq_array( {c.encode(BASE64'STR'):byte(1, 2)}, {0xD8, TAG_BASE64}, "tag 34" )

local t = { 'encoded_as_string', BASE64'encoded_base64' }
local cbor = c.encode(t)
eq_array( c.decode(cbor), { 'encoded_as_string', 'encoded_base64' }, "in a table" )

