# Empire at War Abstraction Layer

[![Build Status](https://secure.travis-ci.org/SvenMarcus/eaw-abstraction-layer.png)](http://secure.travis-ci.org/SvenMarcus/eaw-abstraction-layer)

- [Empire at War Abstraction Layer](#empire-at-war-abstraction-layer)
  - [About](#about)
  - [Installation](#installation)
    - [Installation on Windows](#installation-on-windows)
  - [Usage](#usage)
    - [Project setup](#project-setup)
    - [Running Tests](#running-tests)
      - [busted](#busted)
      - [u-test](#u-test)
      - [Manual testing](#manual-testing)
  - [Currently available EaW functions and types](#currently-available-eaw-functions-and-types)
    - [Functions](#functions)
    - [Types](#types)
      - [faction](#faction)
      - [type](#type)
      - [fleet](#fleet)
      - [game_object](#gameobject)
      - [planet](#planet)
      - [unit_object](#unitobject)
      - [plot](#plot)
      - [event](#event)
  - [Configuration](#configuration)
  - [Writing tests](#writing-tests)
    - [Assertions and matchers](#assertions-and-matchers)
      - [List of assertions and matchers](#list-of-assertions-and-matchers)
  - [Contributing](#contributing)

## About

The Empire at War Abstraction Layer aims to be a drop in replacement for Empire at War's Lua functions, so Lua modules can be executed without launching the game itself. This not only saves time, but also helps with debugging, since the abstraction layer provides additional functioniality to configure the behavior of EaW's functions. The end goal is to provide a set of functions that can be used together in a unit testing framework. The library provides custom assertions for the test frameworks `busted` and `u-test`. We recommend using `busted` due to their included test runner and powerful assertions. Learn more in the [Running Tests](#running-tests) section

## Installation

Either clone this repository or get it on luarocks using:

```bash
luarocks install eaw-abstraction-layer
```

This will install the necessary Lua files, an executable called `eaw-abstraction-layer` that allows you to generate pre-configured test projects as well as `penlight`, a powerful set of libraries that allows easy handling of files and directories.

### Installation on Windows

If you are on Windows it can be tricky to get `luarocks` to run. I recommend installing the Windows Subsystem for Linux (WSL) with Ubuntu:
https://docs.microsoft.com/en-us/windows/wsl/install-win10

Using this you will gain access to a Linux system with all its repositories. Setting up a Lua development environment here is much easier. To get up and running type the following commands in your Linux terminal:

```bash
sudo apt install luajit
sudo apt install luarocks
luarocks install eaw-abstraction-layer
```

From the terminal you can access your Windows drive through the `mnt` folder:

```bash
cd /mnt/c/Program Files (x86)/...
```

## Usage

### Project setup

Use `eaw-abstraction-layer` to generate a configured test project for you.

```bash
eaw-abstraction-layer --new-project
```

This will launch a setup routine that asks you for the target location of your test project and the location of your mod.

It will the generate all the necessary folders for you (including all folders in your test project path that don't exist yet) and a file called `config.lua` that will be run before your tests. It defines the `eaw` global variable that represents the `eaw-abstraction-layer`.

Of course you can also set up a similar folder structure manually.

### Running Tests

#### busted

If you have chosen `busted` in your project setup then the setup routine will have generated a `.busted` file that contains all the necessary information for `busted` to run your test suite. If you haven't installed `busted` yet you can do so by running

```bash
luarocks install busted
```

To run your tests simply open a terminal in your test root folder and run

```bash
busted
```

This command will run the previously mentioned `config.lua` that sets up the Empire at War environment and provide global variables for tests and assertions. In the end you'll end up with the following global variables:

| Variable           | Description                                                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| eaw                | The EaW Abstraction Layer. This will run also run the `eaw.init()` function with the mod path from your `config.lua` file, if present. |
| context / describe | A test context                                                                                                                         |
| test / it          | A function that defines a unit test                                                                                                    |
| assert             | Access to assertions                                                                                                                   |
| spy                | Provides functionality to spy on functions                                                                                             |

To learn more about `busted` check out their great [documentation](https://olivinelabs.com/busted/)

#### u-test

`u-test` currently doesn't ship with a test runner, so you will have to run it manually by calling the necessary functions in a script. Moreover, their version on `luarocks` seems to be outdated by quite a bit, so you should get it directly from their GitHub site: [u-test](https://github.com/IUdalov/u-test)
You'll also find the necessary documentation there.
`u-test` is a way smaller test framework and fits in a single file. It has a great test result output that is inspired by Google Test.

#### Manual testing

To use the library manually, set the path to your mod folder, `require()` a file and choose an entry function.

```lua
local eaw = require "eaw-abstraction-layer"

eaw.init("./examples/Mod")

local function test_eaw_module()
    eaw.run(function()
        require "eaw_module"
        my_eaw_function()
    end)

end

test_eaw_module()
```

If your code uses EaW's built-in global functions you will need to configure them as explained in the following sections.

## Currently available EaW functions and types

### Functions

All of the following functions can be accessed via the EaW environment:

```lua
local env = eaw.environment
local the_function = env.the_function_name
```

| Function                             | Default return value                                                                                               |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Find_First_Object_Of_Type(type_name) | A `game_object` with requested type                                                                                |
| Find_All_Objects_Of_Type             | A `table` with a single `game_object` with requested type                                                          |
| Find_Player                          | A `faction` object with requested name                                                                             |
| Find_Object_Type                     | A `type` with requested name                                                                                       |
| FindPlanet                           | A `planet` object with requested name                                                                              |
| FindPlanet.Get_All_Planets           | A `table` with a single `planet`                                                                                   |
| Find_Nearest                         | A `game_object` with requested type                                                                                |
| Find_Hint                            | A `game_object` with requested type                                                                                |
| Get_Story_Plot                       | A `plot` object                                                                                                    |
| Get_Game_Mode                        | String `"Galactic"`                                                                                                |
| Register_Timer                       | -                                                                                                                  |
| Cancel_Timer                         | -                                                                                                                  |
| Register_Death_Event                 | -                                                                                                                  |
| Register_Attacked_Event              | -                                                                                                                  |
| Cancel_Attacked_Event                | -                                                                                                                  |
| Register_Prox                        | -                                                                                                                  |
| Spawn_Unit                           | A `table` with a `game_object` of requested type                                                                   |
| SpawnList                            | A `table` of multiple `game_objects` of requested types                                                            |
| Story_Event                          | -                                                                                                                  |
| TestValid                            | Boolean `true`                                                                                                     |
| ScriptExit                           | Unlike all other replacement functions ScriptExit is an actual Lua function and cannot receive a callback function |
| Add_Planet_Highlight                 | -                                                                                                                  |
| Hide_Sub_Object                      | -                                                                                                                  |
| Game_Random                          | The first of the two provided input arguments                                                                      |
| Game_Random.GetFloat                 | `number` 0                                                                                                         |
| BlockOnCommand                       | -                                                                                                                  |
| DebugMessage                         | Will print the message using `print(string.format(...))`                                                           |

### Types

#### faction

Usage

```lua
local faction = eaw.types.faction

local player = faction {
    name = "Empire",
    is_human = true
}
```

| Method           | Default return value                                         |
| ---------------- | ------------------------------------------------------------ |
| Get_Faction_Name | Value of field `name`                                        |
| Is_Human         | Value of field `is_human` or `false` if field is not present |
| Make_Ally        | -                                                            |
| Get_Tech_Level   | `number` 1                                                   |

#### type

Usage

```lua
local type = eaw.types.type
local my_type = type("My_Type")
```

| Method   | Default return value      |
| -------- | ------------------------- |
| Get_Name | String with provided name |

#### fleet

Usage

```lua
local fleet = eaw.types.fleet
local my_fleet = fleet()
```

| Method                     | Default return value |
| -------------------------- | -------------------- |
| Get_Contained_Object_Count | `number` 1           |
| Contains_Hero              | Boolean `false`      |
| Contains_Object_Type       | Boolean `true`       |

#### game_object

Usage

```lua
local game_object = eaw.types.game_object
local faction = eaw.types.faction
local my_game_object = game_object {
    name = "type_name",
    owner = faction {
        name = "Empire"
    }
}
```

| Method       | Default return value               |
| ------------ | ---------------------------------- |
| Change_Owner | -                                  |
| Get_Owner    | Value of field `owner`             |
| Get_Type     | A `type` with name of field `name` |

#### planet

Inherits from game_object

Usage

```lua
local planet = eaw.types.planet
local faction = eaw.types.faction
local my_planet = planet {
    name = "planet_name",
    owner = faction {
        name = "Empire"
    }
}
```

| Method                  | Default return value |
| ----------------------- | -------------------- |
| Remove_Planet_Highlight | -                    |
| Get_Final_Blow_Player   | A `faction` object   |

#### unit_object

Inherits from game_object

Usage

```lua
local unit_object = eaw.types.unit_object
local faction = eaw.types.faction
local my_unit = unit_object {
    name = "type_name",
    owner = faction {
        name = "Empire"
    }
}
```

| Method                       | Default return value |
| ---------------------------- | -------------------- |
| Move_To                      | -                    |
| Attack_Move                  | -                    |
| Attack_Target                | -                    |
| Guard_Target                 | -                    |
| Make_Invulnerable            | -                    |
| Teleport                     | -                    |
| Teleport_And_Face            | -                    |
| Turn_To_Face                 | -                    |
| Activate_Ability             | -                    |
| Despawn                      | -                    |
| Enable_Behavior              | -                    |
| Hide                         | -                    |
| In_End_Cinematic             | -                    |
| Lock_Current_Orders          | -                    |
| Override_Max_Speed           | -                    |
| Play_Animation               | -                    |
| Prevent_AI_Usage             | -                    |
| Prevent_Opportunity_Fire     | -                    |
| Reset_Ability_Counter        | -                    |
| Set_Single_Ability_Autofire  | -                    |
| Stop                         | -                    |
| Suspend_Locomotor            | -                    |
| Event_Object_In_Range        | -                    |
| Cancel_Event_Object_In_Range | -                    |
| Are_Engines_Online           | Boolean `true`       |
| Get_Hull                     | Number `1`           |
| Get_Shield                   | Number `1`           |
| Get_Parent_Object            | A `game_object`      |
| Has_Ability                  | Booean `true`        |
| Is_Ability_Active            | Boolean `false`      |
| Is_Under_Effects_Of_Ability  | Boolean `false`      |
| Get_Planet_Location          | A `game_object`      |
| Get_Position                 | -                    |

#### plot

Usage

```lua
local plot = eaw.types.story.plot
local my_plot = plot()
```

| Method    | Default return value |
| --------- | -------------------- |
| Get_Event | An `event`           |
| Activate  | -                    |
| Suspend   | -                    |
| Reset     | -                    |

#### event

Usage

```lua
local event = eaw.types.story.event
local my_event = event()
```

| Method               | Default return value |
| -------------------- | -------------------- |
| Set_Event_Parameter  | -                    |
| Set_Reward_Parameter | -                    |

## Configuration

All functions and types are implemented as callable tables that can be configured to use a callback function when they're being called or to return a specified value.

If, for example, you want to configure `FindPlanet` to return a certain game object and print a message when being called you can do so like this:

```lua
local eaw = require "eaw-abstraction-layer"
local env = eaw.environment
local planet = eaw.types.planet
local faction = eaw.types.faction

function env.FindPlanet.return_value(planet_name)
    return planet {
        name = planet_name,
        owner = faction {
            name = "Empire",
            is_human = true
        }
    }
end

function env.FindPlanet.callback(planet_name)
    print("FindPlanet was called with "..planet_name)
end
```

Since `return_value()` is a function instead of a simple field it allows you to apply more complex logic to a return value.

Functions that are expected to return something will throw a warning if you don't provide a `return_value()` function. However, they will not crash the script. The return value is determined before the `callback()` function is called.
Most functions provide a default return value instead of returning nil.

## Writing tests

The following section describes unit testing with the `busted` test framework. Tests can simply be defined using the `test` or `it` (an alias) function as shown below:

```lua
test("My test name", function()
    -- requiring the abstraction layer will not be necessary with auto generated projects
    local eaw = require "eaw-abstraction-layer"

    local type = eaw.types.type
    local game_object = eaw.types.game_object
    local faction = eaw.types.faction

    function eaw.environment.Spawn_Unit.callback()
        print("I get called when Spawn_Unit is called")
    end

    -- this is a busted spy!
    local s = spy.on(eaw.environment, "Spawn_Unit")

    eaw.run(function()
        Spawn_Unit(Find_Object_Type("DummyType"), FindPlanet("DummyPlanet"), Find_Player("DummyFaction"))
    end)

    assert.spy(s).was.called()
end)
```

### Assertions and matchers

The `eaw-abstraction-layer` defines some custom assertions and matchers that are registered with `busted` when calling `eaw.use_busted()`.
This is done automatically in auto generated projects.

The same can be done for `u-test` with `eaw.use_u_test()`, but has to be done manually (by requiring `config.lua`), since `u-test` does not have a test runner.

Matchers are only available in `busted`.

#### List of assertions and matchers

The currently available assertions/matchers are not final and will be expanded. Contributions are welcome.

| Assertions                                                        |                            |
| ----------------------------------------------------------------- | -------------------------- |
| **busted**                                                        | **u-test**                 |
| assert.is.eaw_type(value)<br/>assert.is_not.eaw_type(value)       | test.is_eaw_type(value)    |
| assert.is.game_object(value)<br/>assert.is_not.game_object(value) | test.is_game_object(value) |
| assert.is.unit_object(value)<br/>assert.is_not.unit_object(value) | test.is_unit_object(value) |
| assert.is.planet(value)<br/>assert.is_not.planet(value)           | test.is_planet(value)      |
| assert.is.faction(value)<br/>assert.is_not.faction(value)         | test.is_faction(value)     |
| assert.is.fleet(value)<br/>assert.is_not.fleet(value)             | test.is_fleet(value)       |
| assert.is.task_force(value)<br/>assert.is_not.task_force(value)   | test.is_task_force(value)  |
| assert.is.plot(value)<br/>assert.is_not.plot(value)               | test.is_plot(value)        |
| assert.is.event(value)<br/>  <br/>assert.is_not.event(value)      | test.is_event(value)       |



| Matchers (busted only)                                         |                     |
| -------------------------------------------------------------- | ------------------- |
| match.game_object { name = "", owner = eaw.types.faction{...}} | `owner` is optional |
| match.faction(faction_name)                                    |                     |
| match.eaw_type(type_name)                                      |                     |



Below is an example on how to use matchers.

```lua

local s = spy.on(eaw.environment, "Spawn_Unit")

eaw.run(function()
    Spawn_Unit(Find_Object_Type("DummyType"), Find_First_Object("Attacker Entry Location"), Find_Player("DummyFaction"))
end)

assert.spy(s).was.called_with(
    match.eaw_type("DummyType"),
    match.game_object { name = "Attacker Entry Location" },
    match.faction {name = "DummyFaction"}
)
```



## Contributing

It's actually really easy to contribute to this project, you don't have to be a Lua expert.
To create a reference for a new EaW function either place it in a fitting existing file or create a new one in `eaw-abstraction-layer/functions`.
A function reference could look like this:

```lua
local metatables = require "eaw-abstraction-layer.core.metatables"
local method = metatables.method

local my_custom_function_creator()
    local My_New_EaW_Function_Reference = method("My_New_EaW_Function_Reference")
    My_New_EaW_Function_Reference.expected = {
        {"game_object", "number"},
        {"game_object"}
    }


    function My_New_EaW_Function_Reference.return_value()
        local something = 0
        return something
    end

    return { My_New_EaW_Function_Reference = My_New_EaW_Function_Reference }
end

return my_custom_function_creator
```

Use the function field `return_value()` to implement a default return value for your new function (only if it's supposed to return something of course). To the end user this is more useful than no default return value, because they won't have to define return values for every function this way. Make sure that your new function references are wrapped in a creator function as shown above. The creator function should be the files' return value.
The field `expected` should be a table where you define the expected input for your function. This field is **NOT** optional! If it is not defined or an empty table the abstraction layer will assume that no input is expected and throw errors if something was received anyway. For multiple possible argument configurations define each variant in a sub table as shown above.
Finally, if you have created a new file, all you need to is add it to the `make_eaw_environment()` function in `environment.lua` like this:

```lua
insert_into_env(env, require "eaw-abstraction-layer.functions.my_file_name" ())
```
