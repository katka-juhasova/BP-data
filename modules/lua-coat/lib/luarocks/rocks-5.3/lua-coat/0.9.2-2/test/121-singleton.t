#!/usr/bin/env lua

require 'Coat'

singleton 'Foo'

has.var = { is = 'rw', isa = 'number' }

require 'Test.More'

plan(6)

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 121.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

local foo = Foo.instance{ var = 4 }
ok( foo:isa 'Foo', "Foo" )
is( foo.var, 4 )

local bar = Foo.instance()
ok( bar:isa 'Foo' )
is( foo, bar )

local baz = Foo()
ok( baz:isa 'Foo' )
is( foo, baz )

