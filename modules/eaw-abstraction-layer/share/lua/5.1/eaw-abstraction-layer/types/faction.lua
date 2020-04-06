local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

local function faction(tab)
    local obj = setmetatable({
        __eaw_type = "faction"
    }, {
        __tostring = function(_)
            return tab.name
        end
    })

    obj.Enable_Advisor_Hints = method("Enable_Advisor_Hints")
    obj.Enable_Advisor_Hints.expected = {
        "string", "boolean"
    }

    obj.Get_Faction_Name = method("Get_Faction_Name")
    function obj.Get_Faction_Name.return_value()
        return string.upper(tab.name)
    end

    obj.Get_ID = method("Get_ID")
    function obj.Get_ID.return_value()
        return 1
    end

    obj.Is_Human = method("Is_Human")
    function obj.Is_Human.return_value()
        return tab.is_human or false
    end

    obj.Get_Tech_Level = method("Get_Tech_Level")
    function obj.Get_Tech_Level.return_value()
        return 1
    end

    obj.Make_Ally = method("Make_Ally")
    obj.Make_Ally.expected = {
        "faction"
    }

    return obj
end

return faction

