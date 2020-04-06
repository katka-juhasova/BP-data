local function copy_fields_to(target, original)
    for k, v in pairs(original) do
        target[k] = v
    end
end

local function shallow_merge(target, ...)
    local objects = { ... }
    for i = 1, #objects do
        local object = objects[i]
        if object then
            copy_fields_to(target, object)
        end
    end

    return target
end

return {
    shallow_merge = shallow_merge
}
