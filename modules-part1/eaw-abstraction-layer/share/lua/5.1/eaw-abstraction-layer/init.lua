local environment = require "eaw-abstraction-layer.core.environment"
local busted_assertions = require "eaw-abstraction-layer.test_framework.busted_assertion_adapters"
local u_test_assertions = require "eaw-abstraction-layer.test_framework.u_test_assertion_adapters"

local types = {
    faction = require "eaw-abstraction-layer.types.faction",
    fleet = require "eaw-abstraction-layer.types.fleet",
    game_object = require "eaw-abstraction-layer.types.game_object",
    global_value = require "eaw-abstraction-layer.global_value",
    planet = require "eaw-abstraction-layer.types.planet",
    story = require "eaw-abstraction-layer.types.story",
    task_force = require "eaw-abstraction-layer.types.task_force",
    type = require "eaw-abstraction-layer.types.type",
    unit_object = require "eaw-abstraction-layer.types.unit_object"
}

return {
    environment = environment.current_environment,
    types = types,
    init = environment.init,
    run = environment.run,
    use_real_errors = environment.use_real_errors,
    use_busted = busted_assertions.use_busted,
    use_u_test = u_test_assertions.use_u_test
}
