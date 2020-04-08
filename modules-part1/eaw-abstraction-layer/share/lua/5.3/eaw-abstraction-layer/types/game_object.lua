local make_type = require "eaw-abstraction-layer.types.type"
local planet = require "eaw-abstraction-layer.types.planet"
local faction = require "eaw-abstraction-layer.types.faction"
local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

-- @usage
-- game_object {
--     name = "Type_Name",
--     owner = faction_object
-- }
local function game_object(tab)

    local obj = { __eaw_type = "game_object" }

    obj.Get_Owner = method("Get_Owner")
    function obj.Get_Owner.return_value()
        return tab.owner
    end

    obj.Change_Owner = method("Change_Owner")
    obj.Change_Owner.expected = {
        "faction"
    }
    function obj.Change_Owner.callback(owner)
        tab.owner = owner
    end

    obj.Despawn = method("Despawn")

    obj.Enable_Behavior = method("Enable_Behavior")
	obj.Enable_Behavior.expected = {
		"number", "boolean"
    }

    obj.Get_Parent_Object = method("Get_Parent_Object")
    function obj.Get_Parent_Object.return_value()
		return game_object {
			name = "DummyObject",
			owner = faction {
                name = "DummyFaction",
                is_human = false
            }
		}
    end

    obj.Get_Planet_Location = method("Get_Planet_Location")
	function obj.Get_Planet_Location.return_value()
        return planet {
            name = "DummyPlanet",
            owner = faction {
                name = "DummyFaction",
                is_human = false
            }
        }
	end

	obj.Get_Position = method("Get_Position")

    local type = make_type(tab.name)

    obj.Get_Type = method("Get_Type")
    function obj.Get_Type.return_value()
        return type
    end

    obj.Hide = method("Hide")
	obj.Hide.expected = {
		"boolean"
	}

    obj.Play_Animation = method("Play_Animation")
	obj.Play_Animation.expected = {
		"string", "boolean", "number"
	}

    return obj
end

return game_object