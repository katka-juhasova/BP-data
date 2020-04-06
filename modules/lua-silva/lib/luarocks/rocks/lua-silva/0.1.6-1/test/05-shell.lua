#!/usr/bin/env lua

require 'Test.More'

plan(40)

local ctor = require 'Silva.shell'

type_ok( ctor, 'function' )

local sme0 = ctor'foo.c'
ok(  sme0, 'foo.c' )
ok(  sme0'foo.c' )
nok( sme0'foo.cpp' )
nok( sme0'foo.h' )
nok( sme0'foo' )
nok( sme0'bar' )

local sme1 = ctor'foo?bar'
ok(  sme1, 'foo?bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo0baz' )
nok( sme1'foo' )
nok( sme1'foo/bar' )

local sme2 = ctor'foo???baz'
ok(  sme2, 'foo???baz' )
ok(  sme2'foobarbaz' )
nok( sme2'foobarbar' )

local sme3 = ctor'?foo'
ok(  sme3, '?foo' )
ok(  sme3'0foo' )
nok( sme3'.foo' )

local sme4 = ctor'foo*'
ok(  sme4, 'foo*' )
ok(  sme4'foo' )
ok(  sme4'foo0' )
ok(  sme4'foo00' )
ok(  sme4'foo000' )
ok(  sme4'foo/000' )

local sme5 = ctor'foo*?'
ok(  sme5, 'foo*?' )
nok( sme5'foo' )
ok(  sme5'foo0' )
ok(  sme5'foo00' )
ok(  sme5'foo000' )
ok(  sme5'foo.000' )
nok( sme5'foo/000' )

local sme6 = ctor'*.c'
ok(  sme6, '*.c' )
ok(  sme6'foo.c' )
nok( sme6'foo.cpp' )
nok( sme6'foo.h' )
nok( sme6'.foo.c' )

local sme7 = ctor'foo/*/*.t'
ok(  sme7, 'foo/*/*.t' )
ok(  sme7'foo/bar/baz.t' )
nok( sme7'foo/bak/.baz.t' )
nok( sme7'foo/.bak/baz.t' )
