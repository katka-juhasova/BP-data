#!/usr/bin/env lua

require 'Test.More'

plan(8)

if not require_ok 'CodeGen' then
    BAIL_OUT "no lib"
end

local m = require 'CodeGen'
type_ok( m, 'table' )
is( m, package.loaded.CodeGen )

is( m._NAME, 'CodeGen', "_NAME" )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'template engine', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

