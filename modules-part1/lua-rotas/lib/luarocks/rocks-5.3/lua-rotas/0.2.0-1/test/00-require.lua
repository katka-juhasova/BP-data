#!/usr/bin/env lua

require 'Test.More'

plan(10)

if not require_ok 'Rotas' then
    BAIL_OUT "no lib"
end

local m = require 'Rotas'
type_ok( m, 'table' )
is( m, package.loaded.Rotas )

is( m._NAME, 'Rotas', "_NAME" )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'web server router', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

eq_array( m.http_methods, { 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE' } )

local o = m()
type_ok( o, 'table', 'instance' )
