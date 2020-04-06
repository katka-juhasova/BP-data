local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

function state_machine()

    local Define_State = method("Define_State")
    Define_State.expected = {
        "string", "function"
    }

    local Set_Next_State = method("Set_Next_State")
    Set_Next_State.expected = {
        "string"
    }

    return {
        Define_State = Define_State,
        Set_Next_State = Set_Next_State
    }
end

return state_machine