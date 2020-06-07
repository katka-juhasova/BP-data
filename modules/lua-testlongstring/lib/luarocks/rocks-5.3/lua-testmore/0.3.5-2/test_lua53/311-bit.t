#! /usr/bin/lua
--
-- lua-TestMore : <http://fperrad.github.com/lua-TestMore/>
--
-- Copyright (C) 2010-2014, Perrad Francois
--
-- This code is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--

--[[

=head1 Lua Bitwise Library

=head2 Synopsis

    % prove 311-bit.t

=head2 Description

Tests Lua Bitwise Library

This library was introduced in Lua 5.2 and deprecated in Lua 5.3.

=cut

--]]

require 'Test.More'

if platform and not platform.compat then
    skip_all("bit32 (removed)")
end

plan(20)

is(bit32.band(0x01, 0x03, 0x07), 0x01, "function band")

if #string.pack('n', 0) == 4 then
    is(bit32.bnot(0x03), (-1 - 0x03), "function bnot")
else
    is(bit32.bnot(0x03), (-1 - 0x03) % 2^32, "function bnot")
end

is(bit32.bor(0x01, 0x03, 0x07), 0x07, "function bor")

is(bit32.btest(0x01), true, "function btest")
is(bit32.btest(0x00), false, "function btest")

is(bit32.bxor(0x01, 0x03, 0x07), 0x05, "function bxor")

is(bit32.lrotate(0x03, 2), 0x0C, "function lrotate")

is(bit32.rrotate(0x06, 1), 0x03, "function rrotate")

is(bit32.arshift(0x06, 1), 0x03, "function arshift")

is(bit32.arshift(-3, 1), bit32.arshift(-6, 2), "function arshift")

is(bit32.lshift(0x03, 2), 0x0C, "function lshift")

is(bit32.rshift(0x06, 1), 0x03, "function rshift")

is(bit32.extract(0xFFFF, 3, 3), 0x07, "function extract")

error_like(function () bit32.extract(0xFFFF, 99) end,
           "^[^:]+:%d+: trying to access non%-existent bits",
           "function extract (non-existent bits)")

error_like(function () bit32.extract(0xFFFF, -3) end,
           "^[^:]+:%d+: bad argument #2 to 'extract' %(field cannot be negative%)",
           "function extract (negatif field)")

error_like(function () bit32.extract(0xFFFF, 3, -3) end,
           "^[^:]+:%d+: bad argument #3 to 'extract' %(width must be positive%)",
           "function extract (negative width)")

is(bit32.replace(0x0000, 0xFFFF, 3, 3), 0x38, "function replace")

error_like(function () bit32.replace(0x0000, 0xFFFF, 99) end,
           "^[^:]+:%d+: trying to access non%-existent bits",
           "function replace (non-existent bits)")

error_like(function () bit32.replace(0x0000, 0xFFFF, -3) end,
           "^[^:]+:%d+: bad argument #3 to 'replace' %(field cannot be negative%)",
           "function replace (negatif field)")

error_like(function () bit32.replace(0x0000, 0xFFFF, 3, -3) end,
           "^[^:]+:%d+: bad argument #4 to 'replace' %(width must be positive%)",
           "function replace (negative width)")

-- Local Variables:
--   mode: lua
--   lua-indent-level: 4
--   fill-column: 100
-- End:
-- vim: ft=lua expandtab shiftwidth=4:
