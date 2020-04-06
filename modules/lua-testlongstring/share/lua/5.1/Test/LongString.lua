--
-- lua-TestLongString : <http://fperrad.github.com/lua-TestLongString/>
--

local pairs = pairs
local tostring = tostring
local type = type
local _G = _G
local math = math
local string = string

local tb = require 'Test.Builder':new()

local _ENV = nil
local m = {}

-- Maximum string length displayed in diagnostics
m.max = 50

-- Amount of context provided when starting displaying a string in the middle
m.context = 10

-- should we show LCSS context ?
m.LCSS = true

-- what a end of line is
m.EOL = "\n"

local function display (str, offset)
    local fmt = '"%s"'
    if str:len() > m.max then
        offset = offset or 1
        if m.context then
            offset = offset - m.context
            if offset < 1 then
                offset = 1
            end
        else
            offset = 1
        end
        if offset == 1 then
            fmt = '"%s"...'
        else
            fmt = '..."%s"...'
        end
        str = str:sub(offset, offset + m.max - 1)
    end
    str = str:gsub( '.',
                function (ch)
                    local val = ch:byte()
                    if val < 32 or val > 127 then
                        return '\\' .. string.format( '%03d', val )
                    else
                        return ch
                    end
                end )
    return string.format( fmt, str )
end

local function common_prefix_length (str1, str2)
    local i = 1
    while true do
        local c1 = str1:sub(i,i)
        local c2 = str2:sub(i,i)
        if not c1 or not c2 or c1 ~= c2 then
            return i
        end
        i = i + 1
    end
end

local function line_column (str, max)
    local init = 1
    local line = 1
    while true do
        local pos, posn = str:find(m.EOL, init)
        if not pos or pos >= max then
            break
        end
        init = posn + 1
        line = line + 1
    end
    return line, max - init + 1
end

function m.is_string(got, expected, name)
    if type(got) ~= 'string' then
        tb:ok(false, name)
        tb:diag("got value isn't a string : " .. tostring(got))
    elseif type(expected) ~= 'string' then
        tb:ok(false, name)
        tb:diag("expected value isn't a string : " .. tostring(expected))
    else
        local pass = got == expected
        tb:ok(pass, name)
        if not pass then
            local common_prefix = common_prefix_length(got, expected)
            local line, column = line_column(got, common_prefix)
            tb:diag("         got: " .. display(got, common_prefix)
               .. "\n      length: " .. tostring(got:len())
               .. "\n    expected: " .. display(expected, common_prefix)
               .. "\n      length: " .. tostring(expected:len())
               .. "\n    strings begin to differ at char " .. tostring(common_prefix) .. " (line "
                                                           .. tostring(line) .. " column "
                                                           .. tostring(column) .. ")")
        end
    end
end

function m.is_string_nows(got, expected, name)
    if type(got) ~= 'string' then
        tb:ok(false, name)
        tb:diag("got value isn't a string : " .. tostring(got))
    elseif type(expected) ~= 'string' then
        tb:ok(false, name)
        tb:diag("expected value isn't a string : " .. tostring(expected))
    else
        local got_nows = got:gsub( "%s+", '' )
        local expected_nows = expected:gsub( "%s+", '' )
        local pass = got_nows == expected_nows
        tb:ok(pass, name)
        if not pass then
            local common_prefix = common_prefix_length(got_nows, expected_nows)
            tb:diag("after whitespace removal:"
               .. "\n         got: " .. display(got_nows, common_prefix)
               .. "\n      length: " .. tostring(got_nows:len())
               .. "\n    expected: " .. display(expected_nows, common_prefix)
               .. "\n      length: " .. tostring(expected_nows:len())
               .. "\n    strings begin to differ at char " .. tostring(common_prefix))
        end
    end
end

function m.like_string(got, pattern, name)
    if type(got) ~= 'string' then
        tb:ok(false, name)
        tb:diag("got value isn't a string : " .. tostring(got))
    elseif type(pattern) ~= 'string' then
        tb:ok(false, name)
        tb:diag("pattern isn't a string : " .. tostring(pattern))
    else
        local pass = got:match(pattern)
        tb:ok(pass, name)
        if not pass then
            tb:diag("         got: " .. display(got)
               .. "\n      length: " .. tostring(got:len())
               .. "\n    doesn't match '" .. pattern .. "'")
        end
    end
end

function m.unlike_string(got, pattern, name)
    if type(got) ~= 'string' then
        tb:ok(false, name)
        tb:diag("got value isn't a string : " .. tostring(got))
    elseif type(pattern) ~= 'string' then
        tb:ok(false, name)
        tb:diag("pattern isn't a string : " .. tostring(pattern))
    else
        local pass = not got:match(pattern)
        tb:ok(pass, name)
        if not pass then
            tb:diag("         got: " .. display(got)
               .. "\n      length: " .. tostring(got:len())
               .. "\n          matches '" .. pattern .. "'")
        end
    end
end

local function lcss (S, T)
    local L = {}
    local offset = 1
    local length = 0
    for i = 1, S:len() do
        for j = 1, T:len() do
            if S:byte(i) == T:byte(j) then
                if i == 1 or j == 1 then
                    L[i] = L[i] or {}
                    L[i][j] = 1
                else
                    L[i-1] = L[i-1] or {}
                    L[i] = L[i] or {}
                    L[i][j] = (L[i-1][j-1] or 0) + 1
                end
                if L[i][j] > length then
                    length = L[i][j]
                    offset = i - length + 1
                end
            end
        end
    end
    return offset, length
end

function m.contains_string(str, substring, name)
    if type(str) ~= 'string' then
        tb:ok(false, name)
        tb:diag("String to look in isn't a string")
    elseif type(substring) ~= 'string' then
        tb:ok(false, name)
        tb:diag("String to look for isn't a string")
    else
        local pass = str:find(substring, 1, true)
        tb:ok(pass, name)
        if not pass then
            tb:diag("    searched: " .. display(str)
               .. "\n  can't find: " .. display(substring))
            if m.LCSS then
                local off, len = lcss(str, substring)
                local l = str:sub(off, off + len - 1)
                tb:diag("        LCSS: " .. display(l))
                if len < m.max then
                    local available = math.ceil((m.max - len) / 2)
                    local begin = off - 2 * available
                    if begin < 1 then
                        begin = off - available
                        if begin < 1 then
                            begin = 1
                        end
                    end
                    local ctx = str:sub(begin, begin + m.max)
                    tb:diag("LCSS context: " .. display(ctx))
                end
            end
        end
    end
end

function m.lacks_string(str, substring, name)
    if type(str) ~= 'string' then
        tb:ok(false, name)
        tb:diag("String to look in isn't a string")
    elseif type(substring) ~= 'string' then
        tb:ok(false, name)
        tb:diag("String to look for isn't a string")
    else
        local idx = str:find(substring, 1, true)
        local pass = not idx
        tb:ok(pass, name)
        if not pass then
            local line, column = line_column(str, idx)
            tb:diag("    searched: " .. display(str)
               .. "\n   and found: " .. display(substring)
               .. "\n at position: " .. tostring(idx) .. " (line "
                                     .. tostring(line) .. " column "
                                     .. tostring(column) .. ")")
        end
    end
end

for k, v in pairs(m) do  -- injection
    if type(v) == 'function' then
        _G[k] = v
    end
end

m._VERSION = "0.2.2"
m._DESCRIPTION = "lua-TestLongString : an extension for testing long string"
m._COPYRIGHT = "Copyright (c) 2009-2018 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
