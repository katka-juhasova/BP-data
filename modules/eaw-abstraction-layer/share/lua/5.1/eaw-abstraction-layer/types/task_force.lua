local game_object = require "eaw-abstraction-layer.types.game_object"
local faction = require "eaw-abstraction-layer.types.faction"
local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

-- @usage
-- task_force {
--	units = {unit_object}
-- }
local function task_force(tab)

    local obj = {
        __eaw_type = "task_force"
    }

    obj.Attack_Move = method("Attack_Move")
    obj.Move_To = method("Move_To")
    obj.Attack_Target = method("Attack_Target")
    obj.Set_As_Goal_System_Removable = method("Set_As_Goal_System_Removable")
    obj.Activate_Ability = method("Activate_Ability")
    obj.Set_Plan_Result = method("Set_Plan_Result")
    obj.Produce_Force = method("Produce_Force")
    obj.Test_Target_Contrast = method("Test_Target_Contrast")
    obj.Build_All = method("Build_All")
    obj.Release_Unit = method("Release_Unit")
    obj.Fire_Orbital_Bombardment = method("Fire_Orbital_Bombardment")
    obj.Set_Targeting_Priorities = method("Set_Targeting_Priorities")
    obj.Guard_Target = method("Guard_Target")
    obj.Collect_All_Free_Units = method("Collect_All_Free_Units")
    obj.Release_Forces = method("Release_Forces")
    obj.Fire_Special_Weapon = method("Fire_Special_Weapon")
    obj.Bombing_Run = method("Bombing_Run")
    obj.Explore_Area = method("Explore_Area")
    obj.Raid = method("Raid")
    obj.Test_Target_Contrast = method("Test_Target_Contrast")
    obj.Build = method("Build")
    obj.Enable_Attack_Positioning = method("Enable_Attack_Positioning")
    obj.Follow_Target = method("Follow_Target")
    obj.Prepare_Ambush = method("Prepare_Ambush")
    obj.Withdraw_Units = method("Withdraw_Units")
    obj.Block_Goal_Proposal = method("Block_Goal_Proposal")
    obj.Land_Units = method("Land_Units")
    obj.Launch_Units = method("Launch_Units")
    obj.Form_Units = method("Form_Units")
    obj.Invade = method("Invade")
    obj.Reinforce = method("Reinforce")

    obj.Get_Unit_Table = method("Get_Unit_Table")
    function obj.Get_Unit_Table.return_value()
        return obj.units
    end

    obj.Get_Goal_Type_Name = method("Get_Goal_Type_Name")
    function obj.Get_Goal_Type_Name.return_value()
        return "Goal_Type_Name"
    end

    obj.Get_Force_Count = method("Get_Force_Count")
    function obj.Get_Force_Count.return_value()
        --might need alternate table counter here
        return #obj.units
    end

    obj.Get_Self_Threat_Max = method("Get_Self_Threat_Max")
    function obj.Get_Self_Threat_Max.return_value()
        --Hard to test what this actually *does*, needs some debug print in-game
        return 0
    end

    obj.Can_Garrison = method("Can_Garrison")
    function obj.Can_Garrison.return_value()
        return false
    end

    obj.Get_Reserved_Build_Pads = method("Get_Reserved_Build_Pads")
    function obj.Get_Reserved_Build_Pads.return_value()
        return obj.units
    end

    obj.Get_Stage = method("Get_Stage")
    function obj.Get_Stage.return_value()
        return game_object {
            name = "DummyPlanet",
            owner = faction {
                name = "DummyFaction",
                is_human = false
            }
        }
    end

    obj.Get_Distance = method("Get_Distance")
    function obj.Get_Distance.return_value()
        return 0
    end

    obj.Is_Raid_Capable = method("Is_Raid_Capable")
    function obj.Is_Raid_Capable.return_value()
        return false
    end

    obj.Are_All_Units_On_Free_Store = method("Are_All_Units_On_Free_Store")
    function obj.Are_All_Units_On_Free_Store.return_value()
        return false
    end

    return obj
end

return task_force
