#!/usr/bin/env lua

require 'Test.More'

plan(4)

local ctor = require 'Silva.identity'

type_ok( ctor, 'function' )

local sme0 = ctor'/foo/bar'
ok( sme0('/foo/bar'), 'same string' )
nok( sme0('/foo/baz') )
nok( sme0('/foo/bar/baz') )
