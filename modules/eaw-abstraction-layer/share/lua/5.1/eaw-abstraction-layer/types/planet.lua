local faction = require "eaw-abstraction-layer.types.faction"
local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method


local function planet(tab)
    local game_object = require "eaw-abstraction-layer.types.game_object"

    local obj = game_object(tab)
    obj.__eaw_type = "planet"

    obj.Remove_Planet_Highlight = method("Remove_Planet_Highlight")
    obj.Remove_Planet_Highlight.expected = {
        "string"
    }

    obj.Get_Final_Blow_Player = method("Get_Final_Blow_Player")
    function obj.Get_Final_Blow_Player.return_value()
        return faction { name = "DummyFaction" }
    end

    return obj
end

return planet