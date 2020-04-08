local GlobalValue = {}
local values = {}

function GlobalValue.Set(key, value)
    if type(key) ~= "string" then
        error("Expected string as GlobalValue key but got "..type(key), 2)
    end

    if type(value) ~= "string" or type(value) ~= "number" then
        error("Expected string or number as GlobalValue value but got "..type(value), 2)
    end

    values[key] = value
end

function GlobalValue.Get(key)
    return values[key]
end

return GlobalValue