local object = {}
local object_mt = {}

function object_mt.__index(class, key)
    local parent = class.__parent
    if parent[key] then
        return parent[key]
    end

    local index = rawget(class, "__index")
    if type(index) == "function" then
        return index(class, key)
    elseif type(index) == "table" then
        return index[key]
    end
end

function object_mt:__tostring(...)
    return self:__tostring(...)
end

local function call_operator(op, a, b)
    if getmetatable(a) == object_mt then
        return a[op](a, b)
    end

    if getmetatable(b) == object_mt then
        return b[op](a, b)
    end
end

function object_mt:__unm() return self:__unm() end
function object_mt.__add(a, b) return call_operator("__add", a, b) end
function object_mt.__sub(a, b) return call_operator("__sub", a, b) end
function object_mt.__mul(a, b) return call_operator("__mul", a, b) end
function object_mt.__div(a, b) return call_operator("__div", a, b) end
function object_mt.__idiv(a, b) return call_operator("__idiv", a, b) end
function object_mt.__mod(a, b) return call_operator("__mod", a, b) end
function object_mt.__pow(a, b) return call_operator("__pow", a, b) end
function object_mt.__concat(a, b) return call_operator("__concat", a, b) end

function object:__tostring()
    return "object: ..."
end

function object:child()
    local o = {}
    o.__parent = self
    setmetatable(o, object_mt)
    return o
end

function object:new(...)
    local o = self:child()

    local init = rawget(self, "__init")
    if init then
        init(o, ...)
    end

    return o
end

return object
