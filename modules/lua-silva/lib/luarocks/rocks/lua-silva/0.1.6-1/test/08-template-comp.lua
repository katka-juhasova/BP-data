#!/usr/bin/env lua

require 'Test.More'

plan(32)

local ctor = require 'Silva.template'

type_ok( ctor, 'function' )

-- level 1
ok( ctor'/foo/bar' )
ok( ctor'/foo/%62%61%7a' )
ok( ctor'/foo/{var}' )
ok( ctor'/foo/{var}/here' )
error_like( function () ctor'/foo/{var-}/' end,
            "invalid character found at position 10" )
error_like( function () ctor'/foo/{var%GG}/' end,
            "invalid triplet found at position 10" )
ok( ctor'/foo/{bar}/{baz}' )
ok( ctor'/foo/{var%20%31}' )
error_like( function () ctor'/foo/{var}/{var}' end,
            "duplicated name var" )
ok( ctor'/foo/{bar}/{%62%61r}' )

-- level 2
ok( ctor'/foo/{+var}' )
ok( ctor'/foo/{+var}/here' )
ok( ctor'/foo/{#var}' )

-- level 3
ok( ctor'/foo/{x,y}' )
ok( ctor'/foo/{+x,y}' )
ok( ctor'/foo/{#x,y}' )
ok( ctor'/foo/{.x,y}' )
ok( ctor'/foo/{/x,y}' )
ok( ctor'/foo/{;x,y}' )
ok( ctor'/foo/{?x,y}' )
ok( ctor'/foo/{&x,y}' )
error_like( function () ctor'/foo/{=var}/' end,
            "operator for future extension found at position 7" )
error_like( function () ctor'/foo/{,var}/' end,
            "operator for future extension found at position 7" )
error_like( function () ctor'/foo/{!var}/' end,
            "operator for future extension found at position 7" )
error_like( function () ctor'/foo/{@var}/' end,
            "operator for future extension found at position 7" )
error_like( function () ctor'/foo/{|var}/' end,
            "operator for future extension found at position 7" )
error_like( function () ctor'/foo/{-var}/' end,
            "invalid character found at position 7" )
error_like( function () ctor'/foo/{x,x,y}' end,
            "duplicated name x" )
error_like( function () ctor'/foo/{x,y,x}' end,
            "duplicated name x" )

-- level 4
error_like( function () ctor'/foo/{var:3}/' end,
            "modifier %(level 4%) found at position 10" )
error_like( function () ctor'/foo/{var*}/' end,
            "modifier %(level 4%) found at position 10" )
