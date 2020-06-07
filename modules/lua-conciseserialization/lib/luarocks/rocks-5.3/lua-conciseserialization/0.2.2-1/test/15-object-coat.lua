#! /usr/bin/lua

require 'Test.More'

if not pcall(require, 'Coat') then
    skip_all 'no Coat'
end

plan(8)

local unpack = table.unpack or unpack
local Meta = require 'Coat.Meta.Class'
local c = require 'CBOR'
local TAG_COAT = 1234

c.coders.table = function (buffer, obj)
    local classname = obj._CLASS
    if classname then
        buffer[#buffer+1] = c.TAG(TAG_COAT)
        buffer[#buffer+1] = c.ARRAY(2)
        c.coders.text_string(buffer, classname)
        c.coders._table(buffer, obj._VALUES)
    else
        c.coders._table(buffer, obj)
    end
end

c.register_tag(TAG_COAT, function (data)
    local classname, values = unpack(data)
    local class = assert(Meta.class(classname))
    return class.new(values)
end)


class 'Point'

has.x = { is = 'ro', isa = 'number', default = 0 }
has.y = { is = 'ro', isa = 'number', default = 0 }
has.desc = { is = 'rw', isa = 'string' }

function overload:__tostring ()
    return '(' .. tostring(self.x) .. ', ' .. tostring(self.y) .. ')'
end

function method:draw ()
    return "drawing " .. self._CLASS .. tostring(self)
end

local a = Point{x = 1, y = 2}
ok( a:isa 'Point' )
is( a:draw(), "drawing Point(1, 2)" )

local b = c.decode(c.encode(a))
ok( b:isa 'Point' )
is( b:draw(), "drawing Point(1, 2)" )

a.desc = string.rep('x', 2^9)
local a9 = c.decode(c.encode(a))
ok( a9:isa 'Point' )
is( #a9.desc, 2^9 )

a.desc = string.rep('x', 2^17)
local a17 = c.decode(c.encode(a))
ok( a17:isa 'Point' )
is( #a17.desc, 2^17 )
