
--
-- lua-Silva : <https://fperrad.frama.io/lua-Silva/>
--

local modname = string.gsub(..., '%.%w+$', '')
local matcher = require(modname).matcher

local pcall = pcall
local require = require
local sub = string.sub
local _ENV = nil
local match

local r, ffi = pcall(require, 'ffi')
if r then
    pcall(function ()
        ffi.cdef"int fnmatch(const char *pattern, const char *string, int flags);"
        local fnmatch = ffi.C.fnmatch
        match = function (s, patt)
            if 0 == fnmatch(patt, s, -1) then
                return s
            end
        end
    end)
end
if not match then
    local posix
    r, posix = pcall(require, 'posix.fnmatch')
    if r then
        local fnmatch = posix.fnmatch
        match = function (s, patt)
            if 0 == fnmatch(patt, s, -1) then
                return s
            end
        end
    end
end
if not match then
    match = function (s, patt, i, j)
        i = i or 1
        j = j or 1
        while j <= #patt do
            local c = sub(s, i, i)
            local p = sub(patt, j, j)
            if     p == '?' then
                if c == '' then
                    return
                end
                if c == '/' then
                    return
                end
                if c == '.' and ((i == 1) or (sub(s, i-1, i-1) == '/')) then
                    return
                end
            elseif p == '*' then
                if c == '.' and ((i == 1) or (sub(s, i-1, i-1) == '/')) then
                    return
                end
                j = j + 1
                p = sub(patt, j, j)
                while p == '?' or p == '*' do
                    if c ==  '/' then
                        return
                    end
                    if p == '?' and c == '' then
                        return
                    end
                    j = j + 1
                    p = sub(patt, j, j)
                    i = i + 1
                    c = sub(s, i, i)
                end
                if c == '' then
                    return s
                end
                while i <= #s do
                    i = i + 1
                    c = sub(s, i, i)
                    if (p == '[' or c == p) and match(s, patt, i, j) then
                        return s
                    end
                end
                return
            elseif p == '[' then
                if c == '' then
                    return
                end
                if c == '.' and ((i == 1) or (sub(s, i-1, i-1) == '/')) then
                    return
                end
                j = j + 1
                p = sub(patt, j, j)
                local compl = (p == '!') or (p == '^')
                if compl then
                    j = j + 1
                    p = sub(patt, j, j)
                end
                local matched
                while true do
                    local cstart, cend = p, p
                    if p == '' then
                        return          -- [ (unterminated)
                    end
                    j = j + 1
                    p = sub(patt, j, j)
                    if p == '/' and not compl then
                        return          -- [/] can never match
                    end
                    if p == '-' and sub(patt, j+1, j+1) ~= ']' then
                        j = j + 1
                        cend = sub(patt, j, j)
                        if cend == '' then
                            return
                        end
                        j = j + 1
                        p = sub(patt, j, j)
                    end
                    if c >= cstart and c <= cend then
                        matched = true
                        while p ~= ']' do       -- skip the rest
                            if p == '' then
                                return          -- [ (unterminated)
                            end
                            j = j + 1
                            p = sub(patt, j, j)
                        end
                        if compl then
                            return
                        end
                        break
                    elseif p == ']' then
                        break
                    end
                end
                if not matched and not compl then
                    return
                end
            else
                if p ~= c then
                    return
                end
            end
            i = i + 1
            j = j + 1
        end
        if sub(s, i, i) == '' then
            return s
        end
    end
end

return matcher(match)
--
-- Copyright (c) 2017-2019 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
