#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'Silva') then
    skip_all 'no Silva'
end

plan(16)

local sme = require 'Silva'
local rotas = require 'Rotas'
rotas.http_methods = { 'GET', 'POST', 'PUT' }

local app = rotas{}
eq_array( app.ALL, { 'GET', 'POST', 'PUT' } )

app.GET[sme('/*.html', 'shell')] = function (path)
    return path
end
app.GET[sme'/foo{?query}'] = function (params)
    return params.query
end
app.ALL[sme'/bar{?query}'] = function (params)
    return params.query
end

error_like( function () app.GET['/foo{?query}'] = false end,
            "key not callable" )

error_like( function () app.PATCH['/foo{?query}'] = false end,
            "attempt to index " )

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
type_ok( fn, 'function' )
res = fn(capture)
is( res, '42' )

fn, capture = app('PUT', '/bar?query=42')
type_ok( fn, 'function' )
res = fn(capture)
is( res, '42' )

fn, capture = app('GET', '/baz?query=42')
nok( fn )
nok( capture )

fn, capture = app('FOO', '/foo')
nok( fn )
nok( capture )

error_like( function () app('ALL', '/index.html') end,
            "allowed only for registration" )
