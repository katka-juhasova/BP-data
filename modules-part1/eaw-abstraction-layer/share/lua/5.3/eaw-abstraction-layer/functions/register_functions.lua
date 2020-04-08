local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

local function register_functions()

    local Register_Timer = method("Register_Timer")
    Register_Timer.expected = {
        {"function", "number"},
        {"function", "number", "any"}
    }

    local Cancel_Timer = method("Cancel_Timer")
    Cancel_Timer.expected = {"function"}

    local Register_Prox = method("Register_Prox")
    Register_Prox.expected = {
        {"game_object", "function", "number"},
        {"unit_object", "function", "number"},
        {"game_object", "function", "number", "faction"},
        {"unit_object", "function", "number", "faction"}
    }

    local Register_Attacked_Event = method("Register_Attacked_Event")
    Register_Attacked_Event.expected = {
        {"game_object", "function"},
        {"unit_object", "function"}
    }

    local Cancel_Attacked_Event = method("Cancel_Attacked_Event")
    Cancel_Attacked_Event.expected = {
        {"game_object"},
        {"unit_object"}
    }

    local Register_Death_Event = method("Register_Death_Event")
    Register_Death_Event.expected = {
        {"game_object", "function"},
        {"unit_object", "function"}
    }

    return {
        Register_Timer = Register_Timer,
        Cancel_Timer = Cancel_Timer,
        Register_Prox = Register_Prox,
        Register_Attacked_Event = Register_Attacked_Event,
        Cancel_Attacked_Event = Cancel_Attacked_Event,
        Register_Death_Event = Register_Death_Event,
    }
end

return register_functions
