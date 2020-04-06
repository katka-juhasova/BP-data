local assertions = require "eaw-abstraction-layer.test_framework.custom_assertions"

local function b_matches_eaw_type(state, args)
    local expected = args[1]
    return function(actual)
        return assertions.matches_eaw_type(expected, actual)
    end
end

local function b_matches_faction(state, args)
    local expected = args[1]
    return function(actual)
        return assertions.matches_faction(expected, actual)
    end
end

local function b_matches_game_object(state, args)
    local expected = args[1]
    return function(actual)
        return assertions.matches_game_object(expected, actual)
    end
end

local function b_is_eaw_type(expected)
    return function(state, args)
        local actual = args[1]
        return assertions.is_eaw_type(expected)(actual)
    end
end



return {
    use_busted = function()
        local say = require "say"
        local assert = require "luassert"

        local function make_type_assertion(type_name, func_name)
            local assert_name = func_name or type_name
            say:set("assertion." .. assert_name .. ".positive", "Expected EaW Type '" .. type_name .. "', but got: %s")
            say:set("assertion." .. assert_name .. ".negative", "Expected to not be EaW Type '" .. type_name .. "'")
            assert:register(
                "assertion",
                assert_name,
                b_is_eaw_type(type_name),
                "assertion." .. assert_name .. ".positive",
                "assertion." .. assert_name .. ".negative"
            )
        end

        -- special case 'type', because assert name needs to be different to avoid confusion with built-in type()
        make_type_assertion("type", "eaw_object_type")

        local types = {"faction", "fleet", "game_object", "planet", "unit_object", "plot", "event", "task_force", "thread"}

        for _, v in pairs(types) do
            make_type_assertion(v)
        end

        assert:register("matcher", "game_object", b_matches_game_object)
        assert:register("matcher", "faction", b_matches_faction)
        assert:register("matcher", "eaw_type", b_matches_eaw_type)
    end
}
