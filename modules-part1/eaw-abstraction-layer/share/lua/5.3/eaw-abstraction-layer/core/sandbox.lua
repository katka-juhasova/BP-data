local sandbox = {}

function sandbox.new()
    local self = setmetatable({}, {__index = sandbox})
    self.table_lookup = {}
    self.__backup = {}
    return self
end

function sandbox:deep_restore(tab, backup)
    self.table_lookup[tab] = true
    for k, v in pairs(tab) do
        if backup[k] == nil then
            tab[k] = nil
        elseif type(v) == "table" and not self.table_lookup[v] then
            self:deep_restore(v, backup[k])
        elseif not type(v) == "table" then
            tab[k] = backup[k]
        end
    end
end

function sandbox:clone_helper(tab)
    local clone = {}
    self.table_lookup[tab] = true
    for k, v in pairs(tab) do
        if type(v) == "table" and not self.table_lookup[v] then
            clone[k] = self:clone_helper(v)
        else
            clone[k] = v
        end
    end

    return clone
end

function sandbox:deep_clone(tab)
    local env_clone = self:clone_helper(tab)
    self.table_lookup = {}
    return env_clone
end

function sandbox:backup()
    self.__backup = self:deep_clone(_G)
end

function sandbox:restore()
    self:deep_restore(_G, self.__backup)
    self.table_lookup = {}
end


function sandbox:run(func)
    local status, err = pcall(coroutine.wrap(func))
    return status, err
end

return sandbox