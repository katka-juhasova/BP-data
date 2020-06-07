#!/usr/bin/env lua

require 'Test.More'

plan(166)

local ctor = require 'Silva.shell'
local sme0, sme1

sme0 = ctor'foo[1234]bar'
ok(  sme0, 'foo[1234]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^1234]bar'
ok(  sme1, 'foo[^1234]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[1-4]bar'
ok(  sme0, 'foo[1-4]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^1-4]bar'
ok(  sme1, 'foo[^1-4]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[12-4]bar'
ok(  sme0, 'foo[12-4]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^12-4]bar'
ok(  sme1, 'foo[^12-4]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[123-4]bar'
ok(  sme0, 'foo[123-4]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^123-4]bar'
ok(  sme1, 'foo[^123-4]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[12-34]bar'
ok(  sme0, 'foo[12-34]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^12-34]bar'
ok(  sme1, 'foo[^12-34]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[1-234]bar'
ok(  sme0, 'foo[1-234]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^1-234]bar'
ok(  sme1, 'foo[^1-234]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[1-34]bar'
ok(  sme0, 'foo[1-34]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^1-34]bar'
ok(  sme1, 'foo[1234]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[1-23-4]bar'
ok(  sme0, 'foo[1-23-4]bar' )
nok( sme0'foo0bar' )
ok(  sme0'foo1bar' )
ok(  sme0'foo2bar' )
ok(  sme0'foo3bar' )
ok(  sme0'foo4bar' )
nok( sme0'foo5bar' )
sme1 = ctor'foo[^1-23-4]bar'
ok(  sme1, 'foo[^1-23-4]bar' )
ok(  sme1'foo0bar' )
nok( sme1'foo1bar' )
nok( sme1'foo2bar' )
nok( sme1'foo3bar' )
nok( sme1'foo4bar' )
ok(  sme1'foo5bar' )

sme0 = ctor'foo[_]bar'
ok(  sme0, 'foo[_]bar' )
nok( sme0'foo bar' )
ok(  sme0'foo_bar' )
sme1 = ctor'foo[^_]bar'
ok(  sme1, 'foo[^_]bar' )
ok(  sme1'foo bar' )
nok( sme1'foo_bar' )

sme0 = ctor'foo[_-]bar'
ok(  sme0, 'foo[_-]bar' )
nok( sme0'foo bar' )
ok(  sme0'foo-bar' )
ok(  sme0'foo_bar' )
sme1 = ctor'foo[^_-]bar'
ok(  sme1, 'foo[^_-]bar' )
ok(  sme1'foo bar' )
nok( sme1'foo-bar' )
nok( sme1'foo_bar' )

sme0 = ctor'foo[-]bar'
ok(  sme0, 'foo[-]bar' )
nok( sme0'foo bar' )
ok(  sme0'foo-bar' )
sme1 = ctor'foo[^-]bar'
ok(  sme1, 'foo[^-]bar' )
ok(  sme1'foo bar' )
nok( sme1'foo-bar' )

sme0 = ctor'foo[-_]bar'
ok(  sme0, 'foo[-_]bar' )
nok( sme0'foo bar' )
ok(  sme0'foo-bar' )
ok(  sme0'foo_bar' )
sme1 = ctor'foo[^_-]bar'
ok(  sme1, 'foo[^_-]bar' )
ok(  sme1'foo bar' )
nok( sme1'foo-bar' )
nok( sme1'foo_bar' )

sme0 = ctor'foo[_,/]bar'
ok(  sme0, 'foo[_,/]bar' )
nok( sme0'foo bar' )
ok(  sme0'foo_bar' )
nok( sme0'foo/bar' )
sme1 = ctor'foo[^_,/]bar'
ok(  sme1, 'foo[^_,/]bar' )
ok(  sme1'foo bar' )
nok( sme1'foo_bar' )
nok( sme1'foo/bar' )

sme0 = ctor'foo['
ok(  sme0, 'foo[' )
nok( sme0'foo ' )
sme1 = ctor'foo[^'
ok(  sme1, 'foo[^' )
nok( sme1'foo ' )

sme0 = ctor'foo[_'
ok(  sme0, 'foo[_' )
nok( sme0'foo_' )
sme1 = ctor'foo[^_'
ok(  sme1, 'foo[^_' )
nok( sme1'foo_' )

sme0 = ctor'foo[_-'
ok(  sme0, 'foo[_-' )
nok( sme0'foo_' )
sme1 = ctor'foo[^_-'
ok(  sme1, 'foo[^_-' )
nok( sme1'foo_' )

sme0 = ctor'foo[.]c'
ok(  sme0, 'foo[.]c' )
ok(  sme0'foo.c' )
nok( sme0'foo:c' )
nok( sme0'foo' )

sme0 = ctor'[.]foo'
ok(  sme0, '[.]foo' )
nok( sme0'.foo' )
