#!/usr/bin/env lua

local Coat = require 'Coat'

local class = Coat.class('Rect')

Coat.has(class, 'x', { is = 'rw', isa = 'number', required = true })
Coat.has(class, 'y', { is = 'rw', isa = 'number', required = true })

Coat.method(class, 'getArea', function (self) return self.x * self.y end)

require 'Test.More'

plan(5)

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 181.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

type_ok( class, 'table', "Coat" )
is( class, Rect )
local r = Rect{ x = 2, y = 4 }
is( r:type(), 'Rect', "Rect" )
ok( r:isa(class) )
is( r:getArea(), 8, "area" )

