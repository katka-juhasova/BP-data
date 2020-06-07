local assertions = require "eaw-abstraction-layer.test_framework.custom_assertions"

return {
    use_u_test = function()
        local test = require "u-test"
        test.register_assert("matches_eaw_type", assertions.matches_eaw_type)
        test.register_assert("matches_faction", assertions.matches_faction)
        test.register_assert("matches_game_object", assertions.matches_game_object)
        test.register_assert("is_eaw_type", assertions.is_eaw_type("type"))
        test.register_assert("is_faction", assertions.is_eaw_type("faction"))
        test.register_assert("is_fleet", assertions.is_eaw_type("fleet"))
        test.register_assert("is_game_object", assertions.is_eaw_type("game_object"))
        test.register_assert("is_planet", assertions.is_eaw_type("planet"))
        test.register_assert("is_unit_object", assertions.is_eaw_type("unit_object"))

        test.register_assert("is_plot", assertions.is_eaw_type("plot"))
        test.register_assert("is_event", assertions.is_eaw_type("event"))

        test.register_assert("is_task_force", assertions.is_eaw_type("task_force"))
    end
}