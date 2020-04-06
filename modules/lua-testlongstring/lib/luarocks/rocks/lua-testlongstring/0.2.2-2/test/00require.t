#! /usr/bin/lua

require 'Test.More'
plan(8)

if not require_ok 'Test.LongString' then
    BAIL_OUT "no lib"
end

local m = require 'Test.LongString'
type_ok( m, 'table' )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'extension', "_DESCRIPTION" )
like( m._VERSION, '^%d%.%d%.%d$', "_VERSION" )

is( m.max, 50, "max" )
is( m.context, 10, "context" )
is( m.LCSS, true, "LCSS" )
