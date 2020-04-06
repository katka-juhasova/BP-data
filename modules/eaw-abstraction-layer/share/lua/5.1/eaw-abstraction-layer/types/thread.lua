local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

local function thread()

    local obj = {}
    obj.__eaw_type = "thread"

    obj.Kill = method("Kill")

    return obj
end

return thread