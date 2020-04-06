#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'Silva') then
    skip_all 'no Silva'
end

plan(8)

local sme = require 'Silva'
local rotas = require 'Rotas'

local app = rotas{}
app.GET[sme('/index.html', 'identity')] = function (path)
    return path
end
app.GET[sme('/foo%?query=(%d+)', 'lua')] = function (params)
    return params[1]
end

local fn, capture, res
fn, capture = app('GET', '/index.html')
type_ok( fn, 'function' )
res = fn(capture)
is( res, '/index.html' )

fn, capture = app('GET', '/foo?query=42')
type_ok( fn, 'function' )
res = fn(capture)
is( res, '42' )

fn, capture = app('GET', '/bar?query=42')
nok( fn )
nok( capture )

fn, capture = app('FOO', '/foo')
nok( fn )
nok( capture )

