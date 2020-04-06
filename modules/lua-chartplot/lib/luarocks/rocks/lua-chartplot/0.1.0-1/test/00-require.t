#!/usr/bin/env lua

require 'Test.More'

plan(16)

if not require_ok 'ChartPlot' then
    BAIL_OUT "no lib"
end

local m = require 'ChartPlot'
type_ok( m, 'table', 'module' )
is( m, package.loaded['ChartPlot'], 'package.loaded' )

local o = m.new()
type_ok( o, 'table', 'instance' )
type_ok( o.setData, 'function', 'meth setData' )
type_ok( o.setTag, 'function', 'meth setTag' )
type_ok( o.setGraphOptions, 'function', 'meth setGraphOptions' )
type_ok( o.getBounds, 'function', 'meth getBounds' )
type_ok( o.draw, 'function', 'meth draw' )
type_ok( o.getGDobject, 'function', 'meth getGDobject' )
type_ok( o.data2px, 'function', 'meth data2px' )

is( m._NAME, 'ChartPlot', "_NAME" )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'plot two dimensional data', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )
