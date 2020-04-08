#!/usr/bin/env lua

require 'Test.More'

plan(10)

if not require_ok 'Silva' then
    BAIL_OUT "no lib"
end

local m = require 'Silva'
type_ok( m, 'table' )
is( m, package.loaded.Silva )

type_ok( m.matcher, 'function', 'matcher' )
type_ok( m.array_matcher, 'function', 'array_matcher' )

is( m._NAME, 'Silva', "_NAME" )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'string matching expert', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

