#!/usr/bin/env lua

require 'Test.More'

plan(20)

local re = require 'Silva.lua'
local uri = require 'Silva.template'

local sme0 = uri('/foo{+path}{.ext}')   -- both captures are greedy, and the second could succeed with empty
local t = sme0('/foo/index.html')
type_ok( t, 'table' )
is( t.path, '/index.html' )
is( t.ext, nil )

local sme1 = re'^/foo(.-)%.(%w+)$'      -- the first capture is non greedy
t = sme1('/foo/index.html')
type_ok( t, 'table' )
is( t[1], '/index' )
is( t[2], 'html' )

--
--  level 4 of URI Template is not implemented
--  example of prefix value: /foo{dir:1,dir:2,dir,file}
--
local sme2 = uri('/foo{/dir_1,dir_2,dir,file}')
t = sme2('/foo/S/SI/SILVA/bar.txt')
type_ok( t, 'table' )
is( t.dir_1, 'S' )
is( t.dir_2, 'SI' )
is( t.dir, 'SILVA' )
is( t.file, 'bar.txt' )
ok( sme2('/foo/S/AB/SILVA/bar.txt') )
ok( sme2('/foo/S/SI/ABCDE/bar.txt') )

local sme3 = re('^/foo/(%w)/(%1%w)/(%2%w*)/(.*)$')
t = sme3('/foo/S/SI/SILVA/bar.txt')
type_ok( t, 'table' )
is( t[1], 'S' )
is( t[2], 'SI' )
is( t[3], 'SILVA' )
is( t[4], 'bar.txt' )
nok( sme3('/foo/S/AB/SILVA/bar.txt') )
nok( sme3('/foo/S/SI/ABCDE/bar.txt') )
