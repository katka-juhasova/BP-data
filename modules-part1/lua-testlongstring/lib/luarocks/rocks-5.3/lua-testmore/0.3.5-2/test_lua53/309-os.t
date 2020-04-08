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

=head1 Lua Operating System Library

=head2 Synopsis

    % prove 309-os.t

=head2 Description

Tests Lua Operating System Library

See "Lua 5.3 Reference Manual", section 6.9 "Operating System Facilities",
L<http://www.lua.org/manual/5.3/manual.html#6.9>.

See "Programming in Lua", section 22 "The Operating System Library".

=cut

--]]

require 'Test.More'

plan(53)

local lua = (platform and platform.lua) or arg[-1]

local clk = os.clock()
type_ok(clk, 'number', "function clock")
ok(clk <= os.clock())

local d = os.date('!*t', 0)
is(d.year, 1970, "function date")
is(d.month, 1)
is(d.day, 1)
is(d.hour, 0)
is(d.min, 0)
is(d.sec, 0)
is(d.wday, 5)
is(d.yday, 1)
is(d.isdst, false)

is(os.date('!%d/%m/%y %H:%M:%S', 0), '01/01/70 00:00:00', "function date")

like(os.date('%H:%M:%S'), '^%d%d:%d%d:%d%d', "function date")

is(os.date('%Oy', 0), '70')
error_like(function () os.date('%Ja', 0) end,
           "^[^:]+:%d+: bad argument #1 to 'date' %(invalid conversion specifier '%%Ja'%)",
           "function date (invalid)")

is(os.difftime(1234, 1200), 34, "function difftime")

local res = os.execute()
is(res, true, "function execute")

local r, s, n = os.execute('__IMPROBABLE__')
is(r, nil, "function execute")
is(s, 'exit')
type_ok(n, 'number')

local cmd = lua .. [[ -e "print '# hello from external Lua'; os.exit(2)"]]
r, s, n = os.execute(cmd)
is(r, nil)
is(s, 'exit', "function execute & exit")
is(n, 2, "exit value")

cmd = lua .. [[ -e "print '# hello from external Lua'; os.exit(false)"]]
r, s, n = os.execute(cmd)
is(r, nil)
is(s, 'exit', "function execute & exit")
is(n, 1, "exit value")

cmd = lua .. [[ -e "print '# hello from external Lua'; os.exit(true, true)"]]
is(os.execute(cmd), true, "function execute & exit")

cmd = lua .. [[ -e "print 'reached'; os.exit(); print 'not reached';"]]
local f
r, f = pcall(io.popen, cmd)
if r then
    is(f:read'*l', 'reached', "function exit")
    is(f:read'*l', nil)
    local code = f:close()
    is(code, true, "exit code")
else
    skip("io.popen not supported", 3)
end

cmd = lua .. [[ -e "print 'reached'; os.exit(3); print 'not reached';"]]
r, f = pcall(io.popen, cmd)
if r then
    is(f:read'*l', 'reached', "function exit")
    is(f:read'*l', nil)
    r, s, n = f:close()
    is(r, nil)
    is(s, 'exit', "exit code")
    is(n, 3, "exit value")
else
    skip("io.popen not supported", 5)
end

is(os.getenv('__IMPROBABLE__'), nil, "function getenv")

local user = os.getenv('LOGNAME') or os.getenv('USERNAME')
type_ok(user, 'string', "function getenv")

f = io.open('file.rm', 'w')
f:write("file to remove")
f:close()
r = os.remove("file.rm")
is(r, true, "function remove")

local msg
r, msg = os.remove('file.rm')
is(r, nil, "function remove")
like(msg, '^file.rm: No such file or directory')

f = io.open('file.old', 'w')
f:write("file to rename")
f:close()
os.remove('file.new')
r = os.rename('file.old', 'file.new')
is(r, true, "function rename")
os.remove('file.new') -- clean up

r, msg = os.rename('file.old', 'file.new')
is(r, nil, "function rename")
like(msg, 'No such file or directory')

is(os.setlocale('C', 'all'), 'C', "function setlocale")
is(os.setlocale(), 'C')

is(os.setlocale('unk_loc', 'all'), nil, "function setlocale (unknown locale)")

like(os.time(), '^%d+%.?%d*$', "function time")

like(os.time(nil), '^%d+%.?%d*$', "function time")

like(os.time({
    sec = 0,
    min = 0,
    hour = 0,
    day = 1,
    month = 1,
    year = 2000,
    isdst = 0,
}), '^946%d+$', "function time")

if string.packsize('l') == 8 then
    skip('64bit platforms')
else
    error_like(function () os.time({
        sec = 0,
        min = 0,
        hour = 0,
        day = 1,
        month = 1,
        year = 1000,
        isdst = 0,
    }) end,
               "^[^:]+:%d+: time result cannot be represented in this installation",
               "function time (invalid)")
end

error_like(function () os.time{} end,
           "^[^:]+:%d+: field 'day' missing in date table",
           "function time (missing field)")

local fname = os.tmpname()
type_ok(fname, 'string', "function tmpname")
ok(fname ~= os.tmpname())

-- Local Variables:
--   mode: lua
--   lua-indent-level: 4
--   fill-column: 100
-- End:
-- vim: ft=lua expandtab shiftwidth=4:
