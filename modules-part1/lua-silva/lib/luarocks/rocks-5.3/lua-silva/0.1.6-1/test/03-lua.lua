#!/usr/bin/env lua

require 'Test.More'

plan(8)

local ctor = require 'Silva.lua'

type_ok( ctor, 'function' )

local sme0 = ctor'^hello'
local sme1 = ctor'^(h.ll.)'
local sme2 = ctor'^(h.)l(l.)'

ok( sme0('hello') )
ok( sme0('hello world') )
nok( sme0('Hello world') )

eq_array( sme1('hello world'), {'hello'})
nok( sme1('Hello world') )

eq_array( sme2('hello world'), {'he', 'lo'})
nok( sme2('Hello world') )
