local sandbox = require "eaw-abstraction-layer.core.sandbox"
local game_object = require "eaw-abstraction-layer.types.game_object"
local faction = require "eaw-abstraction-layer.types.faction"

local env = {state = {}}
local real_errors = false
local env_ready = false
local __path_backup = package.path
local __mod_path

local function yellow(str) return "\27[1;33m" .. tostring(str) .. "\27[0m" end
local function red(str) return "\27[1;31m" .. tostring(str) .. "\27[0m" end

local function warning(msg) print(yellow(msg)) end

local function raise_error(msg, lvl) error(red(msg), lvl) end

local function insert_into_env(env, tab)
    for func_name, func in pairs(tab) do env[func_name] = func end
end

local make_finders = require "eaw-abstraction-layer.functions.finders"
local make_register_functions = require "eaw-abstraction-layer.functions.register_functions"
local make_story = require "eaw-abstraction-layer.functions.story"
local make_utilities = require "eaw-abstraction-layer.functions.utilities"
local make_spawn = require "eaw-abstraction-layer.functions.spawn"
local make_state_machine = require "eaw-abstraction-layer.functions.state_machine"

local function make_eaw_environment()
    local env = {}

    insert_into_env(env, make_finders())
    insert_into_env(env, make_register_functions())
    insert_into_env(env, make_story())
    insert_into_env(env, make_utilities())
    insert_into_env(env, make_spawn())
    insert_into_env(env, make_state_machine())
    insert_into_env(env, {
        OnEnter = 0,
        OnUpdate = 1,
        OnExit = 2,
        Object = game_object {
            name = "Default_Object",
            owner = faction {
                name = "Default_Faction",
                is_human = true
            }
        }
    })

    env.GlobalValue = require "eaw-abstraction-layer.global_value"
    return env
end

local function init(mod_path)
    env.state = make_eaw_environment()
    env_ready = true
    __mod_path = mod_path
end

local function prepare_package_path()
    if not __mod_path then return end
    __path_backup = package.path

    local scripts = __mod_path .. "/Data/Scripts/"
    local script_folders = {
        scripts .. "AI/",
        scripts .. "Library/",
        scripts .. "Story/",
        scripts .. "GameObject/",
        scripts .. "Evaluators/",
        scripts .. "Miscellaneous/",
        scripts .. "FreeStore/",
        scripts .. "Interventions/"
    }

    for _, path in pairs(script_folders) do package.path = package.path .. ";" .. path .. "?.lua" end
end

local function prepare_environment()
    if not env_ready then env.state = make_eaw_environment() end

    prepare_package_path()

    package.loaded.PGAICommands = true
    package.loaded.PGBase = true
    package.loaded.PGBaseDefinitions = true
    package.loaded.PGCommands = true
    package.loaded.PGDebug = true
    package.loaded.PGEvents = true
    package.loaded.PGInterventions = true
    package.loaded.PGMoveUnits = true
    package.loaded.PGSpawnUnits = true
    package.loaded.PGStateMachine = true
    package.loaded.PGStoryMode = true
    package.loaded.PGTaskForce = true

    insert_into_env(_G, env.state)
end

local function reset_environment()
    env.state = make_eaw_environment()
    package.path = __path_backup
    env_ready = false
end

local function run(func, ...)
    local sb = sandbox.new()
    sb:backup()
    prepare_environment()
    local status, err = sb:run(func, ...)
    reset_environment()
    sb:restore()

    if status then return end

    if real_errors then
        raise_error(err)
    end

    warning(err)
end

local function use_real_errors(bool) real_errors = bool end

return {
    init = init,
    run = run,
    use_real_errors = use_real_errors,
    current_environment = setmetatable(
        {},
        {
            __index = function(_, k)
                if not env_ready then env.state = make_eaw_environment() end
                return env.state[k]
            end,
            __newindex = function(_, k, v) env.state[k] = v end
        }
    )
}
