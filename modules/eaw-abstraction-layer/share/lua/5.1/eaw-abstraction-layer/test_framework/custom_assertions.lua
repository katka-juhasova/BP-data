local function wrong_type_message(expected_type, actual)
    local msg = type(actual)
    if actual.Get_Type then
        msg = actual.Get_Type()
    end

    return "Expected '"..expected_type.."'. Got: "..tostring(msg)
end

local function matches_eaw_type(expected, actual)
    local msg

    if type(actual) ~= "table" or not actual.Get_Name then
        return false, wrong_type_message("type", actual)
    end

    msg = "Type does not match:\n"
    local actual_msg = msg.."Actual: "..actual.Get_Name()

    if type(expected) == "table" and expected.Get_Name then
        msg = msg.."Expected: "..expected.Get_Name()..actual_msg
        return expected.Get_Name() == actual.Get_Name(), msg
    end

    msg = msg.."Expected: "..string.upper(expected)..actual_msg
    return string.upper(expected) == actual.Get_Name(), msg
end

local function matches_faction(expected, actual)
    if type(actual) ~= "table" or not actual.Get_Faction_Name then
        return false, wrong_type_message("faction", actual)
    end

    local matches, msg
    if type(expected) == "table" and expected.Get_Faction_Name then
        msg = "Expected faction: "..expected.Get_Faction_Name()..", but got: "..actual.Get_Faction_Name()
        matches = expected.Get_Faction_Name() == actual.Get_Faction_Name()
        return matches, msg
    end

    msg = "Expected faction: "..expected..", but got: "..actual.Get_Faction_Name()
    return string.upper(expected) == actual.Get_Faction_Name(), msg
end

local function matches_game_object(expected, actual)
    local matches = true
    local type_match, faction_match, msg
    local base_msg = "Game object does not match:\n"

    if expected.Get_Type then
        local expected_eaw_type = expected.Get_Type()
        local expected_owner = expected.Get_Owner()

        type_match, msg = matches_eaw_type(expected_eaw_type, actual.Get_Type())
        matches = matches and type_match
        if not matches then
            return matches, base_msg..msg
        end

        faction_match, msg = matches_faction(expected_owner, actual.Get_Owner())
        matches = matches and faction_match

        if not matches then
            return matches, base_msg..msg
        end
    end

    if expected.name then
        type_match, msg = matches_eaw_type(expected.name, actual.Get_Type())
        matches = matches  and type_match
        if not matches then
            base_msg = base_msg..msg
        end
    end

    if expected.owner then
        matches, msg = matches_faction(expected.owner, actual.Get_Owner())
        if not matches then
            base_msg = base_msg..msg
        end
    end

    if matches then
        return true
    else
        return false, base_msg
    end
end

local function is_eaw_type(expected_type)
    return function(actual)
        if type(actual) == "table" then
           return actual.__eaw_type == expected_type
        end

        return false
    end
end

return {
    is_eaw_type = is_eaw_type,
    matches_eaw_type = matches_eaw_type,
    matches_game_object = matches_game_object,
    matches_faction = matches_faction
}


