
--
-- lua-Silva : <https://fperrad.frama.io/lua-Silva>
--

local require = require
local setmetatable = setmetatable
local _ENV = nil
local modname = ...
local m = {}

function m.matcher (match, compile)
    if compile then
        return function (patt)
            local ops = compile(patt)
            return function (s)
                return match(s, ops)
            end
        end
    else
        return function (patt)
            return function (s)
                return match(s, patt)
            end
        end
    end
end

function m.array_matcher (match)
    return function (patt)
        return function (s)
            local capt = { match(s, patt) }
            if #capt == 0 then
                return nil
            end
            if s == capt[1] then
                return s
            else
                return capt
            end
        end
    end
end

local cache = setmetatable({}, {
    __index = function (t, k)
        local v = require(modname .. '.' .. k)
        t[k] = v
        return v
    end
})

local function new (patt, type)
    type = type or 'template'
    return cache[type](patt)
end

setmetatable(m, {
    __call = function (_, ...) return new(...) end
})

m._NAME = modname
m._VERSION = "0.1.6"
m._DESCRIPTION = "lua-Silva : your personal string matching expert"
m._COPYRIGHT = "Copyright (c) 2017-2019 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
