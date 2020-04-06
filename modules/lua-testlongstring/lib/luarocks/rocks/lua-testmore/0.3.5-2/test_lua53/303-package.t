#! /usr/bin/lua
--
-- lua-TestMore : <http://fperrad.github.com/lua-TestMore/>
--
-- Copyright (C) 2009-2015, Perrad Francois
--
-- This code is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--

--[[

=head1 Lua Package Library

=head2 Synopsis

    % prove 303-package.t

=head2 Description

Tests Lua Package Library

See "Lua 5.3 Reference Manual", section 6.3 "Modules",
L<http://www.lua.org/manual/5.3/manual.html#6.3>.

=cut

--]]

require 'Test.More'

plan(28)

ok(package.loaded._G, "table package.loaded")
ok(package.loaded.coroutine)
ok(package.loaded.io)
ok(package.loaded.math)
ok(package.loaded.os)
ok(package.loaded.package)
ok(package.loaded.string)
ok(package.loaded.table)

type_ok(package.config, 'string')
type_ok(package.cpath, 'string')
type_ok(package.path, 'string')

type_ok(package.preload, 'table', "table package.preload")
is(# package.preload, 0)

type_ok(package.searchers, 'table', "table package.searchers")
is(package.loaders, nil)

local m = require 'Test.More'
m.ok(true, "function require")
is(m, package.loaded['Test.More'])

local p = package.searchpath('Test.More', package.path)
type_ok(p, 'string', "searchpath")
p = package.searchpath('Test.More', 'bad path')
is(p, nil)

local f = io.open('complex.lua', 'w')
f:write [[
complex = {}

function complex.new (r, i) return {r=r, i=i} end

--defines a constant 'i'
complex.i = complex.new(0, 1)

function complex.add (c1, c2)
    return complex.new(c1.r + c2.r, c1.i + c2.i)
end

function complex.sub (c1, c2)
    return complex.new(c1.r - c2.r, c1.i - c2.i)
end

function complex.mul (c1, c2)
    return complex.new(c1.r*c2.r - c1.i*c2.i,
                       c1.r*c2.i + c1.i*c2.r)
end

local function inv (c)
    local n = c.r^2 + c.i^2
    return complex.new(c.r/n, -c.i/n)
end

function complex.div (c1, c2)
    return complex.mul(c1, inv(c2))
end

return complex
]]
f:close()
m = require 'complex'
is(m, complex, "function require")
is(complex.i.r, 0)
is(complex.i.i, 1)
os.remove('complex.lua') -- clean up

error_like(function () require('no_module') end,
           "^[^:]+:%d+: module 'no_module' not found:",
           "function require (no module)")

f = io.open('foo.lua', 'w')
f:write [[?syntax error?]]
f:close()
error_like(function () require('foo') end,
           "^error loading module 'foo' from file '%.[/\\]foo%.lua':",
           "function require (syntax error)")
os.remove('foo.lua') -- clean up

local foo = {}
foo.bar = 1234
local function foo_loader ()
    return foo
end
package.preload.foo = foo_loader
m = require 'foo'
assert(m == foo)
is(m.bar, 1234, "function require & package.preload")

f = io.open('bar.lua', 'w')
f:write [[
    print("    in bar.lua", ...)
    a = ...
]]
f:close()
a = nil
require 'bar'
is(a, 'bar', "function require (arg)")
os.remove('bar.lua') -- clean up

f = io.open('cplx.lua', 'w')
f:write [[
-- print('cplx.lua', ...)
local _G = _G
_ENV = nil
local cplx = {}

local function new (r, i) return {r=r, i=i} end
cplx.new = new

--defines a constant 'i'
cplx.i = new(0, 1)

function cplx.add (c1, c2)
    return new(c1.r + c2.r, c1.i + c2.i)
end

function cplx.sub (c1, c2)
    return new(c1.r - c2.r, c1.i - c2.i)
end

function cplx.mul (c1, c2)
    return new(c1.r*c2.r - c1.i*c2.i,
               c1.r*c2.i + c1.i*c2.r)
end

local function inv (c)
    local n = c.r^2 + c.i^2
    return new(c.r/n, -c.i/n)
end

function cplx.div (c1, c2)
    return mul(c1, inv(c2))
end

_G.cplx = cplx
return cplx
]]
f:close()
require 'cplx'
is(cplx.i.r, 0, "function require & module")
is(cplx.i.i, 1)
os.remove('cplx.lua') -- clean up

-- Local Variables:
--   mode: lua
--   lua-indent-level: 4
--   fill-column: 100
-- End:
-- vim: ft=lua expandtab shiftwidth=4:
