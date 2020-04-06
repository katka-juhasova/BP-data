local _M = {}

_M.__index = _M

function _M.new(cookieString)
    local self = setmetatable({}, _M)
    self.data = {}
    self.flags = {}
    if cookieString ~= nil then
        for keyValue in string.gmatch(cookieString, "([^;]+)") do
            key, value = string.match(keyValue, " *([^=]+)=(.+)")
            if key == nil or value == nil then
                self.flags[string.match(keyValue, " *([^=]+)")] = true
            else
                self.data[key] = value
            end
        end
    end
    return self 
end

function _M:toString()
    local first = true 
    local buffer = {}
    for key, value in pairs(self.data) do
        if first then
            first = false
        else
            table.insert(buffer, "; ")
        end
        table.insert(buffer, key .. "=" .. value)
    end
    for key, value in pairs(self.flags) do
        if value == true then
            if first then
                first = false
            else
                table.insert(buffer, "; ")
            end
            table.insert(buffer, key)
        end
    end
    return table.concat(buffer)
end

return _M
