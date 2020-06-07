#!/usr/bin/env lua

require 'Test.More'

plan(5)

local sme = require 'Silva'

local sme0 = sme('/foo/bar', 'identity')
ok( sme0('/foo/bar'), 'same string' )
nok( sme0('/foo/baz') )

local sme1 = sme'/foo/{var}'
local t = sme1('/foo/bar')
type_ok( t, 'table' )
is( t.var, 'bar' )
nok( sme1('/bar/baz') )

