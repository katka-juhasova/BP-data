# lua-gear
Inversion of Control implementation in lua

[![Build Status](https://travis-ci.org/basiliscos/lua-gear.png)](https://travis-ci.org/basiliscos/lua-gear)

If you know Java spring framework https://spring.io/ , this library is may be for you. The Inversion of Control https://en.wikipedia.org/wiki/Inversion_of_control approach allows you to get rid of Singleton https://en.wikipedia.org/wiki/Singleton_pattern anti-pattern, and more easily manage complex depencencies.

The `gear` library *optionally* provide Dependecy Injection https://en.wikipedia.org/wiki/Dependency_injection via custom *resolver*; The `gear` cannot do DI as the as there is no reflection in lua, but custom OO-libraries _might_ provide that.

# Synopsis

## Chicken / egg problem

```lua
local Gear = require "gear"
local gear = Gear.create()
gear:declare("chicken", {
  dependencies = {"egg"},                                            -- optional
  constructor  = function() return { class = "chicken" } end,
  initializer  = function(g, instance, egg) instance.egg = egg end,  -- optional
})
gear:declare("egg", {
  dependencies = {"chicken"},
  constructor  = function() return { class = "egg" } end,
  initializer  = function(g, instance, chicken) instance.chicken = chicken end,
})

-- solved!
local chicken = gear:get("chicken")
print(chiken.class)
print(chiken.egg.class)
local egg = gear:get("egg")
print(egg.class)
print(egg.chiken.class)

```

# API

```lua
local Gear = require "gear"
local gear = Gear.create()          -- construct the container

-- the order of declaring components does NOT matter

gear:declare("car",                                                -- component name, required
  {                                                                -- component descriptor, required
    dependencies = {"wheels", "engine", "data/year"},              -- list of names of dependecies, optional
    resolver     = function(component_name)                        -- "dynamic" dependencies, needed for DI
      return {"wheels", "engine", "data/year"}
    end,
    constructor = function()                                       -- constructor, required
      return { class = "car" },                                    -- must return something non-nill
    end,
    initializer = function(gear, instance, wheels, engine, year)   -- initializer, optional
      instance.wheels = wheels
      instance.engine = engine
      instance.year   = year
    end
  }
)

-- simple constructors
gear:declare("wheels",function() return { class = "wheels" } end)
gear:declare("engine",function() return { class = "engine" } end)

-- directly set pre-initialized (or externally initialized components)
gear:set("data/year", 2015)

-- Voila!
local engine = gear:get("engine") 
```

# Dependency injection example

Dependency Injection is possible when underlying class-system provides field-level fields enumeration for used classes, and class can be dynamically looked up via it's name. 

For example lua-Coat https://github.com/fperrad/lua-Coat provides that. Simplified example

```lua

require 'Coat'

local meta = require 'Coat.Meta.Class'

class 'Egg'
has.name = { is = 'ro' }
has.chicken = { is = 'ro', isa = 'Chicken' }

class 'Chicken'
has.egg = { is = 'ro', isa = 'Egg' }

local resolver = function(component_name)
  -- drop "my/" prefix
  local my_class_name = string.sub(component_name, 4)
  local my_class = _ENV[my_class_name]
  local dependencies = {}
  for name, attr in meta.attributes(my_class) do
    local property_class_name = attr.isa
    local property_class = _ENV[property_class_name]
    if (property_class) then
      -- add "my/" prefix
      table.insert(dependencies, "my/" .. property_class_name)
    end
  end
  return dependencies
end

local Gear = require "gear"
local gear = Gear.create()

gear:declare("my/Chicken", {
  resolver    = resolver,
  constructor = function() return Chicken { } end,
  initializer = function(gear, instance, egg) instance.egg = egg end,
})
gear:declare("my/Egg", {
  resolver    = resolver,
  constructor = function() return Egg { name = "smallie" } end,
  initializer = function(gear, instance, chicken) instance.chicken = chicken end,
})

local chicken = gear:get("my/Chicken")
print(chicken.egg.name)

```

# Installation

`luarocks install gear`

# License 

Artistic License 2.0

# Author

Ivan Baidakou (basiliscos), https://github.com/basiliscos
