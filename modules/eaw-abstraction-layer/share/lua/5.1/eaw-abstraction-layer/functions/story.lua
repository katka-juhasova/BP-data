local story_types = require "eaw-abstraction-layer.types.story"
local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

local function story()

    --TODO: verify signature
    local Check_Story_Flag = method("Check_Story_Flag")
    Check_Story_Flag.expected = {
        "faction", "string", "any", "boolean"
    }

    function Check_Story_Flag.return_value()
        return false
    end

    local Get_Story_Plot = method("Get_Story_Plot")
    Get_Story_Plot.expected = {
        "string"
    }

    function Get_Story_Plot.return_value()
        return story_types.plot()
    end;

    local Story_Event = method("Story_Event")
    Story_Event.expected = {
        "string"
    }

    return {
        Check_Story_Flag = Check_Story_Flag,
        Get_Story_Plot = Get_Story_Plot,
        Story_Event = Story_Event
    }
end

return story