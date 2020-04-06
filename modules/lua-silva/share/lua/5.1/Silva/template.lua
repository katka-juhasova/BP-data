
--
-- lua-Silva : <https://fperrad.frama.io/lua-Silva/>
--

local modname = string.gsub(..., '%.%w+$', '')
local matcher = require(modname).matcher

local char = string.char
local error = error
local tonumber = tonumber
local tostring = tostring
local sub = string.sub
local gmatch = string.gmatch
local gsub = string.gsub
local _ENV = nil

local function convert (n)
    return char(tonumber(n, 16))
end

local function unescape (s, query)
    if query then
        s = gsub(s, '+', ' ')   -- x-www-form-urlencoded
    end
    return (gsub(s, '%%(%x%x)', convert))
end

local legal_op = {
    ['0'] = false,      -- literal
    ['1'] = false,      -- unreserved character string expansion
    ['+'] = true,       -- reserved character string expansion
    ['#'] = true,       -- fragment expansion, crosshatch-prefixed
    ['.'] = true,       -- label expansion, dot-prefixed
    ['/'] = true,       -- path segments, slash-prefixed
    [';'] = true,       -- path-style parameters, semicolon-prefixed
    ['?'] = true,       -- form-style query, ampersand-separated
    ['&'] = true,       -- form-style query continuation
}

local future_op = {
    ['='] = true,
    [','] = true,
    ['!'] = true,
    ['@'] = true,
    ['|'] = true,
}

local is_hexa = {
    ['0'] = true, ['1'] = true, ['2'] = true, ['3'] = true, ['4'] = true,
    ['5'] = true, ['6'] = true, ['7'] = true, ['8'] = true, ['9'] = true,
    ['A'] = true, ['B'] = true, ['C'] = true, ['D'] = true, ['E'] = true, ['F'] = true,
    ['a'] = true, ['b'] = true, ['c'] = true, ['d'] = true, ['e'] = true, ['f'] = true,
}

local is_word = {
    ['0'] = true, ['1'] = true, ['2'] = true, ['3'] = true, ['4'] = true,
    ['5'] = true, ['6'] = true, ['7'] = true, ['8'] = true, ['9'] = true,
    ['A'] = true, ['B'] = true, ['C'] = true, ['D'] = true, ['E'] = true, ['F'] = true,
    ['G'] = true, ['H'] = true, ['I'] = true, ['J'] = true, ['K'] = true, ['L'] = true,
    ['M'] = true, ['N'] = true, ['O'] = true, ['P'] = true, ['Q'] = true, ['R'] = true,
    ['S'] = true, ['T'] = true, ['U'] = true, ['V'] = true, ['W'] = true, ['X'] = true,
    ['Y'] = true, ['Z'] = true,
    ['_'] = true,
    ['a'] = true, ['b'] = true, ['c'] = true, ['d'] = true, ['e'] = true, ['f'] = true,
    ['g'] = true, ['h'] = true, ['i'] = true, ['j'] = true, ['k'] = true, ['l'] = true,
    ['m'] = true, ['n'] = true, ['o'] = true, ['p'] = true, ['q'] = true, ['r'] = true,
    ['s'] = true, ['t'] = true, ['u'] = true, ['v'] = true, ['w'] = true, ['x'] = true,
    ['y'] = true, ['z'] = true,
}

local function compile (patt)
    local exist = {}
    local function uniq (name)
        if exist[name] then
            error("duplicated name " .. name, 4)
        end
        exist[name] = true
        return name
    end  -- uniq

    local ops = {}
    local ip = 1
    for start, _end in gmatch(patt, "()%b{}()") do
        if start > ip then
            ops[#ops+1] = { '0', unescape(sub(patt, ip, start - 1)) }
        end
        ip = _end
        local s = sub(patt, start + 1, _end - 2)
        local c = sub(s, 1, 1)
        if future_op[c] then
            error("operator for future extension found at position " .. tostring(start + 1), 3)
        end
        local op = {}
        local i
        if legal_op[c] then
            op[1] = c
            i = 2
        else
            op[1] = '1'
            i = 1
        end
        local j = i
        while i <= #s do
            c = sub(s, i, i)
            if not is_word[c] then
                if     c == ',' then
                    op[#op+1] = uniq(sub(s, j, i - 1))
                    j = i + 1
                elseif c == '%' then
                    if not is_hexa[sub(s, i+1, i+1)] or not is_hexa[sub(s, i+2, i+2)] then
                        error("invalid triplet found at position " .. tostring(start + i), 3)
                    end
                    i = i + 2
                elseif c == ':' or c == '*' then
                    error("modifier (level 4) found at position " .. tostring(start + i), 3)
                else
                    error("invalid character found at position " .. tostring(start + i), 3)
                end
            end
            i = i + 1
        end
        if i ~= j then
            op[#op+1] = uniq(sub(s, j, i))
        end
        ops[#ops+1] = op
    end
    if #patt > ip then
        ops[#ops+1] = { '0', unescape(sub(patt, ip)) }
    end
    return ops
end

local end_oper = {
    ['1'] = { ['/'] = true, ['?'] = true, ['#'] = true },
    ['+'] = { ['?'] = true, ['#'] = true },
    ['#'] = {},
    ['.'] = { ['/'] = true, ['?'] = true, ['#'] = true },
    ['/'] = { ['?'] = true, ['#'] = true },
    [';'] = { ['/'] = true, ['?'] = true, ['#'] = true },
    ['?'] = { ['#'] = true },
    ['&'] = { ['#'] = true },
}

local sep_var = {
    ['1'] = ',',
    ['+'] = ',',
    ['#'] = ',',
    ['.'] = '.',
    ['/'] = '/',
    [';'] = ';',
    ['?'] = '&',
    ['&'] = '&',
}

local function match (s, ops)
    local capture = {}
    local query = false

    local function inner (i, ip)
        for k = ip, #ops do
            local op = ops[k]
            local oper = op[1]
            if     oper == '0' then
                local literal = op[2]
                for j = 1, #literal do
                    local p = sub(literal, j, j)
                    local c = sub(s, i, i)
                    i = i + 1
                    if c == '%' and is_hexa[sub(s, i, i)] and is_hexa[sub(s, i+1, i+1)] then
                        c = convert(sub(s, i, i+1))
                        i = i + 2
                    else
                        if c == '+' and query then
                            c = ' '     -- x-www-form-urlencoded
                        end
                        if c == '?' then
                            query = true
                        end
                        if c == '#' then
                            query = false
                        end
                    end
                    if c ~= p then
                        return
                    end
                end
            elseif oper == ';' or oper == '?' or oper == '&' then
                local c = sub(s, i, i)
                if c == oper then
                    if c == '?' then
                        query = true
                    end
                    i = i + 1
                    local keys = {}
                    for j = 2, #op do
                        keys[op[j]] = true
                    end
                    local start = i
                    local key
                    while i <= #s do
                        while i <= #s do
                            c = sub(s, i, i)
                            if c == '=' or c == ';' or end_oper[oper][c] then
                                break
                            end
                            i = i + 1
                        end
                        if start == i and end_oper[oper][c] then
                            break
                        end
                        key = sub(s, start, i-1)
                        if not keys[key] then
                            return
                        end
                        start = i + 1
                        if oper == ';' and (c == ';' or end_oper[';'][c]) then
                            capture[key] = ''
                            if end_oper[oper][c] then
                                break
                            end
                            i = i + 1
                        else
                            while i <= #s do
                                c = sub(s, i, i)
                                if c == sep_var[oper] then
                                    capture[key] = unescape(sub(s, start, i-1), query)
                                    i = i + 1
                                    start = i
                                    break
                                end
                                if end_oper[oper][c] then
                                    break
                                end
                                i = i + 1
                            end
                        end
                        if end_oper[oper][c] then
                            break
                        end
                    end
                    if key then
                        if k == #ops then
                            capture[key] = unescape(sub(s, start, i-1), query)
                        else
                            local sav = query
                            for j = i, start, -1 do
                                if inner(j, k+1) then
                                    capture[key] = unescape(sub(s, start, j-1), sav)
                                    return true
                                end
                            end
                        end
                    end
                end
            else
                local c = sub(s, i, i)
                if oper == '1' or oper == '+' or oper == c then
                    if c == '#' then
                        query = false
                    end
                    if oper ~= '1' and oper ~= '+' then
                        i = i + 1
                    end
                    local start = i
                    local nvar = 2
                    local varname = op[nvar]
                    while i <= #s do
                        c = sub(s, i, i)
                        if c == sep_var[oper] then
                            capture[varname] = unescape(sub(s, start, i-1), query)
                            if (oper == '/' or oper == '.') and not op[nvar+1] then
                                break
                            else
                                nvar = nvar + 1
                                varname = op[nvar]
                                if not varname then
                                    return
                                end
                            end
                            start = i + 1
                        elseif end_oper[oper][c] then
                            break
                        end
                        i = i + 1
                    end
                    if k == #ops then
                        capture[varname] = unescape(sub(s, start, i-1), query)
                    else
                        local sav = query
                        for j = i, start, -1 do
                            if inner(j, k+1) then
                                capture[varname] = unescape(sub(s, start, j-1), sav)
                                return true
                            end
                        end
                    end
                end
            end
        end
        if i > #s then
            return true
        end
    end  -- inner

    if inner(1, 1) then
        if #ops == 1 and ops[1][1] == '0' then
            return s
        else
            return capture
        end
    end
end

return matcher(match, compile)
--
-- Copyright (c) 2017-2019 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
