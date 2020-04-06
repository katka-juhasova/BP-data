local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

local function event()
    local obj = {
        __eaw_type = "event"
    }

    obj.Set_Event_Parameter = method("Set_Event_Parameter")
    obj.Set_Event_Parameter.expected = {
        { "number", "string" },
        { "number", "number" },
        { "number", "game_object" },
        { "number", "unit_object" },
        { "number", "planet" }
    }
    obj.Set_Reward_Parameter = method("Set_Reward_Parameter")

    return obj
end

local function plot()
    local obj = {
        __eaw_type = "plot"
    }
    obj.Get_Event = method("Get_Event")
    obj.Get_Event.expected = {
        "string"
    }
    function obj.Get_Event.return_value()
        return event()
    end

    obj.Activate = method("Activate")
    obj.Suspend = method("Suspend")
    obj.Reset = method("Reset")

    return obj
end

return {
    plot = plot,
    event =event
}