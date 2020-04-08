local luaconfig = {}
luaconfig.__index = luaconfig

--
-- trim string
--
local function trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end

--
-- validates a key if conforms key pattern
--
local function validatekey(key)
    assert(key)
	assert(key:match("[%w_%-/]+"),
		   "invalid config key ("..tostring(key)..")")
end

--
-- substitute reference
--
local function subst(self, value, history)
	local c
	repeat
		value, c = value:gsub("($%b())", function(key)
			key = key:sub(3, -2)
			while key:find("$%(") do
				key = subst(self, key, history)
			end
			local deref = self:get(key, false, history)
			if not deref then
				error(string.format("can't substitute reference `%s''", key))
			end
			return deref
		end)
	until c == 0
	return value
end

function luaconfig:set(key, value)
	validatekey(key)
    local multiline = key
    if type(value) ~= "nil" then
        -- in case the value is given interpret single line config setter
        multiline = string.format("%s=%s", key, tostring(value))
    end
    local continuation = false
    local key, value
    for line in multiline:gmatch("[^\n]+") do
        -- strip comments
        line = line:gsub("(%-%-.*)", "")

        -- trim
        line = trim(line)

        if continuation then
            value = trim(value:sub(1, -2))
            value = value..line
        else
            key, value = line:match("(.-)=(.*)")
        end
        continuation = line:sub(-1) == "\\" and line:sub(-2,-2) ~= "\\"
        if key and not continuation then
            -- set value with type as a string
            value = trim(tostring(value))
            self:_set(trim(key), value)
            key, value = nil, nil
        end
    end
end

--
-- get configuration property value
--
function luaconfig:get(key, nosubst, history)
    -- check for cyclic references in get history
    history = history or {}
    for i, v in ipairs(history) do
        if v == key then
            error(string.format("Cyclic substitution detected by key `%s':\n%s", key, table.concat(history, ",")))
        end
    end
    table.insert(history, key)

    -- get value from driver
    local value = self:_get(key)

    if value then
        -- try substitude value references 
        value = (not nosubst and subst(self, value, history)) or value

        -- unescape
        value = value:gsub("\\(.)", "%1")

        -- guess value type
        value = tonumber(value) or value
        
        if value == "true" then
            value = true
        elseif value == "false" then
            value = false
        end
    end
    table.remove(history)
    return value
end

function luaconfig:keys()
    return self:_keys()
end

function luaconfig:values()
    local values = {}
    for _, key in ipairs(self:keys()) do
        table.insert(values, self:get(key))
    end
    return values
end

local memory_impl = setmetatable({}, luaconfig)
memory_impl.__index = memory_impl

function memory_impl:_set(key, value)
    self[key] = value
end

function memory_impl:_get(key)
    return self[key]
end

function memory_impl:_keys()
    local keys = {}
    for k in pairs(self) do
        table.insert(keys, k)
    end
    return keys
end

return setmetatable(luaconfig, {
    __call = function(_, impl)
        if impl then
            local iscallable = function(f) 
                return type(f) == "function" or (type(f) == "table" and type(getmetatable(f).__call) == "function")
            end
            for k in pairs(memory_impl) do
                if iscallable(memory_impl[k]) then
                    assert(iscallable(impl[k]), string.format("Missing %s function implementation", k))
                end
            end
            return setmetatable(impl, luaconfig)
        else
            return setmetatable({}, memory_impl)
        end
    end
})
