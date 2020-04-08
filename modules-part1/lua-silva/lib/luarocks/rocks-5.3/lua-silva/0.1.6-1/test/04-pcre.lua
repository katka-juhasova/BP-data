#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'rex_pcre') then
    skip_all 'no rex_pcre'
end

plan(7)

local ctor = require 'Silva.pcre'

type_ok( ctor, 'function' )

local sme0 = ctor'^hello'
local sme1 = ctor'^(h.ll.)'
local sme2 = ctor'^(h.)l(l.)'

ok( sme0('hello world') )
nok( sme0('Hello world') )

eq_array( sme1('hello world'), {'hello'})
nok( sme1('Hello world') )

eq_array( sme2('hello world'), {'he', 'lo'})
nok( sme2('Hello world') )
