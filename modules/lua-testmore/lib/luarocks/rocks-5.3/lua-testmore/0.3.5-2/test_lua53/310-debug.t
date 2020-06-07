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

=head1 Lua Debug Library

=head2 Synopsis

    % prove 310-debug.t

=head2 Description

Tests Lua Debug Library

See "Lua 5.3 Reference Manual", section 6.10 "The Debug Library",
L<http://www.lua.org/manual/5.3/manual.html#6.10>.

See "Programming in Lua", section 23 "The Debug Library".

=cut

]]

require 'Test.More'

plan(50)

local debug = require 'debug'

local info = debug.getinfo(is)
type_ok(info, 'table', "function getinfo (function)")
is(info.func, is, " .func")

info = debug.getinfo(is, 'L')
type_ok(info, 'table', "function getinfo (function, opt)")
type_ok(info.activelines, 'table')

info = debug.getinfo(1)
type_ok(info, 'table', "function getinfo (level)")
like(info.func, "^function: [0]?[Xx]?%x+", " .func")

is(debug.getinfo(12), nil, "function getinfo (too depth)")

error_like(function () debug.getinfo('bad') end,
           "bad argument #1 to 'getinfo' %(.- expected",
           "function getinfo (bad arg)")

error_like(function () debug.getinfo(is, 'X') end,
           "bad argument #2 to 'getinfo' %(invalid option%)",
           "function getinfo (bad opt)")

local name, value = debug.getlocal(0, 1)
type_ok(name, 'string', "function getlocal (level)")
is(value, 0)

error_like(function () debug.getlocal(42, 1) end,
           "bad argument #1 to 'getlocal' %(level out of range%)",
           "function getlocal (out of range)")

name, value = debug.getlocal(like, 1)
type_ok(name, 'string', "function getlocal (func)")
is(value, nil)

local t = {}
is(debug.getmetatable(t), nil, "function getmetatable")
local t1 = {}
debug.setmetatable(t, t1)
is(debug.getmetatable(t), t1)

local a = true
is(debug.getmetatable(a), nil)
debug.setmetatable(a, t1)
is(debug.getmetatable(t), t1)

a = 3.14
is(debug.getmetatable(a), nil)
debug.setmetatable(a, t1)
is(debug.getmetatable(t), t1)

local reg = debug.getregistry()
type_ok(reg, 'table', "function getregistry")
type_ok(reg._LOADED, 'table')

name = debug.getupvalue(plan, 1)
type_ok(name, 'string', "function getupvalue")

debug.sethook()
local hook, mask, count = debug.gethook()
is(hook, nil, "function gethook")
is(mask, '')
is(count, 0)
local function f () end
debug.sethook(f, 'c', 42)
hook , mask, count = debug.gethook()
is(hook, f, "function gethook")
is(mask, 'c')
is(count, 42)

local co = coroutine.create(function () print "thread" end)
hook = debug.gethook(co)
is(hook, nil, "function gethook(thread)")

name = debug.setlocal(0, 1, 0)
type_ok(name, 'string', "function setlocal (level)")

name = debug.setlocal(0, 42, 0)
is(name, nil, "function setlocal (level)")

error_like(function () debug.setlocal(42, 1, true) end,
           "bad argument #1 to 'setlocal' %(level out of range%)",
           "function getlocal (out of range)")

t = {}
t1 = {}
is(debug.setmetatable(t, t1), t, "function setmetatable")
is(getmetatable(t), t1)

error_like(function () debug.setmetatable(t, true) end,
           "^[^:]+:%d+: bad argument #2 to 'setmetatable' %(nil or table expected%)")

name = debug.setupvalue(plan, 1, require 'Test.Builder':new())
type_ok(name, 'string', "function setupvalue")

name = debug.setupvalue(plan, 42, true)
is(name, nil)

local u = io.tmpfile()
local old = debug.getuservalue(u)
is(old, nil, "function getuservalue")
is(debug.getuservalue(true), nil)
local data = {}
local r = debug.setuservalue(u, data)
is(r, u, "function setuservalue")
is(debug.getuservalue(u), data)
r = debug.setuservalue(u, old)
is(debug.getuservalue(u), old)

error_like(function () debug.setuservalue({}, data) end,
           "^[^:]+:%d+: bad argument #1 to 'setuservalue' %(userdata expected, got table%)")

like(debug.traceback(), "^stack traceback:\n", "function traceback")

like(debug.traceback("message\n"), "^message\n\nstack traceback:\n", "function traceback with message")

like(debug.traceback(false), "false", "function traceback")

local id = debug.upvalueid(plan, 1)
type_ok(id, 'userdata', "function upvalueid")

debug.upvaluejoin (pass, 1, fail, 1)

error_like(function () debug.upvaluejoin(true, 1, nil, 1) end,
           "bad argument #1 to 'upvaluejoin' %(function expected, got boolean%)",
           "function upvaluejoin (bad arg)")

error_like(function () debug.upvaluejoin(pass, 1, true, 1) end,
           "bad argument #3 to 'upvaluejoin' %(function expected, got boolean%)",
           "function upvaluejoin (bad arg)")

-- Local Variables:
--   mode: lua
--   lua-indent-level: 4
--   fill-column: 100
-- End:
-- vim: ft=lua expandtab shiftwidth=4:
