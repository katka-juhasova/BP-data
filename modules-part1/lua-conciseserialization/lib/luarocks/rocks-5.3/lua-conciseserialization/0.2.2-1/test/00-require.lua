#! /usr/bin/lua

require 'Test.More'

plan(8)

if not require_ok 'CBOR' then
    BAIL_OUT "no lib"
end

local m = require 'CBOR'
type_ok( m, 'table' )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'ConciseSerialization', "_DESCRIPTION" )
like( m._VERSION, '^%d%.%d%.%d$', "_VERSION" )

type_ok( m.coders, 'table', "table coders" )
type_ok( m.decode_cursor, 'function', "function decode_cursor" )
type_ok( m.MAGIC, 'string', "CBOR MAGIC" )

if m.full64bits then
    diag "full 64bits with Lua 5.3"
end
