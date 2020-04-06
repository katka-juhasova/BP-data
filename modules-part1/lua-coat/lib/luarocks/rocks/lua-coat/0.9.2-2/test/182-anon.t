#!/usr/bin/env lua

local Coat = require 'Coat'

local class = Coat.class()

Coat.has(class, 'x', { is = 'rw', isa = 'number', required = true })
Coat.has(class, 'y', { is = 'rw', isa = 'number', required = true })

Coat.method(class, 'getArea', function (self) return self.x * self.y end)

require 'Test.More'

plan(4)

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 182.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

type_ok( class, 'table', "Coat" )
local r = class{ x = 2, y = 4 }
like( r:type(), '_ANON_%d', "Rect" )
ok( r:isa(class) )
is( r:getArea(), 8, "area" )

