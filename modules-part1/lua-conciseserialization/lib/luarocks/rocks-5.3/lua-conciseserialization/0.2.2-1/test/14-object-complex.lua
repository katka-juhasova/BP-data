#! /usr/bin/lua

require 'Test.More'

plan(2)

local unpack = table.unpack or unpack
local c = require 'CBOR'
local TAG_COMPLEX = 42

local Cplx = {}
do
    Cplx.__index = Cplx

    function Cplx.new (re, im)
        local obj = {
            re = tonumber(re),
            im = im ~= nil and tonumber(im) or 0.0,
        }
        return setmetatable(obj, Cplx)
    end

    function Cplx:__tostring ()
        return '(' .. tostring(self.re) .. ', ' .. tostring(self.im) .. ')'
    end

    function Cplx:tocbor (buffer)
        buffer[#buffer+1] = c.TAG(TAG_COMPLEX)
        buffer[#buffer+1] = c.ARRAY(2)
        c.coders.number(buffer, self.re)
        c.coders.number(buffer, self.im)
    end
end

c.coders.table = function (buffer, obj)
    local mt = getmetatable(obj)
    if mt and mt.tocbor then
        obj:tocbor(buffer)
    else
        c.coders._table(buffer, obj)
    end
end

c.register_tag(TAG_COMPLEX, function (data)
    local re, im = unpack(data)
    return Cplx.new(re, im)
end)


local a = Cplx.new(1, 2)
is( tostring(a), '(1, 2)' )

local b = c.decode(c.encode(a))
is( tostring(b), '(1, 2)' )

