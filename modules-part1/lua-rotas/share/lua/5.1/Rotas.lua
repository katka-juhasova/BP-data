
--
-- lua-Rotas : <https://fperrad.frama.io/lua-Rotas>
--

local assert = assert
local error = error
local rawset = rawset
local setmetatable = setmetatable
local type = type

local _ENV = nil
local m = {}
local mt = {}

m.http_methods = {
    'DELETE',
    'GET',
    'HEAD',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
    'TRACE',
}

local function build ()
    local cache = {}
    return setmetatable({}, {
        __newindex = function (t, k, v)
            assert(type(k) == 'function', 'key not callable')
            rawset(t, #t+1, k)
            cache[k] = v
        end,
        __call = function (t, url)
            for i = 1, #t do
                local sme = t[i]
                local capture = sme(url)
                if capture then
                    return cache[sme], capture
                end
            end
            return nil
        end,
    })
end

function mt.__call (t, meth, url)
    if t[meth] then
        return t[meth](url)
    end
end

local function new (t)
    t = t or {}
    local all = {}
    for i = 1, #m.http_methods do
        local meth = m.http_methods[i]
        all[#all+1] = meth
        t[meth] = build()
    end
    t.ALL = setmetatable(all, {
        __newindex = function (ta, k, v)
            for i = 1, #ta do
                local meth = ta[i]
                t[meth][k] = v
            end
        end,
        __call = function ()
            error('allowed only for registration')
        end,
    })
    return setmetatable(t, mt)
end

setmetatable(m, {
    __call = function (_, ...) return new(...) end
})

m._NAME = ...
m._VERSION = "0.2.0"
m._DESCRIPTION = "lua-Rotas : a web server router"
m._COPYRIGHT = "Copyright (c) 2018-2019 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
