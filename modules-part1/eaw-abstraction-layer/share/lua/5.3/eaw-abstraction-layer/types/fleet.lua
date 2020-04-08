local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

function fleet()
    local obj = {
        __eaw_type = "fleet"
    }

    obj.Get_Contained_Object_Count = method("Get_Contained_Object_Count")
    function obj.Get_Contained_Object_Count.return_value()
        return 1
    end

    obj.Contains_Hero = method("Contains_Hero")
    function obj.Contains_Hero.return_value()
        return false
    end

    obj.Contains_Object_Type = method("Contains_Object_Type")
    obj.Contains_Object_Type.expected = {
        "type"
    }

    function obj.Contains_Object_Type.return_value(_)
        return true
    end

    return obj
end

return fleet