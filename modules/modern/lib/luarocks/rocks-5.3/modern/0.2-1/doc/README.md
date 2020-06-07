![Modern](https://raw.githubusercontent.com/skrolikowski/Modern/master/brand.png)

A module/mixin system written in the Lua programming language.

* [Use Case](#Use-Case)
* [Installation](#Installation)
* [Getting Started](#Getting-Started)
* [Usage](#Usage)
* [Examples](#Examples)
* [API](#API)
* [License](#License)

## Use Case

A **module** can be thought of as a unit (of code), which is used to facilitate a more complex purpose (our program). Lua doesn't naturally come pre-built with the idea of a `class`, however it offers the power of `metatables` to imitate inheritance. This idea is the main idea behind `Modern`, but with a bit more.

### What's in the box?

**Inheritance** - any modules can extend any other module.

**Mixins** - extend your modules beyond their ability without affecting the inheritance chain. Functions with the same name will compound into one function call.

**Utility Functions** - check out the [API](#API)

## Installation

**Direct Download**

1. Download the latest release from Modern's [release page](https://github.com/skrolikowski/Modern/releases).
2. Unpack and upload to a folder that is recognized by `LUA_PATH`.

**LuaRocks**

```
luarocks install modern
```

## Getting Started

1) Simply include `modern` within a new file.

```lua
local Modern = require 'modern'
```

2) Extend from `Modern` to create a fresh module, inheriting all it's functionality.

```lua
local Player = Modern:extend()
```

3) Now you can add additional functionality to your module.

```Lua
-- `new` automatically runs when Module is called
function Player:new(x, y)
	self.x = x
    self.y = y
end
```

## Usage

### Polymorphism

`Modern` allows you to create polymorphic relationships with other `Modules`.

```lua
local Modern = require 'modern'
local Enemy  = Modern:extend() -- inherits everything from `Modern`
local Orc    = Enemy:extend()  -- inherits everything from `Enemy`
local Troll  = Enemy:extend()  -- inherits everything from `Enemy`
```

### Mixins

`Mixins` are added as arguments when calling `extend`. You can add another `Module` or a basic `table` as an argument. Any functions with conflicting names will compound so that they are all fired in sequence when called.

```lua
local Modern = require 'modern'
local AABB   = require 'mixins.AABB'
local FSM    = require 'mixins.FSM'
local Enemy  = Modern:extend(AABB, FSM)
```

A use case for using `Mixins` would be adding a **F**inite **S**tate **M**achine to your `Module` (in this case `Enemy`). It doesn't make sense to inherit from `FSM`, but we want to include the functionality to update our `Enemy` states each game cycle. By adding `FSM` as a mixin expands the base `Module`'s functionality.

### Names & Namespaces

Every `Module` is provided a name &  namespace upon creation (`__call()` and  `extend()`). The `__name` is just the variable name you assigned the `Module`, while the `__namespace` can be thought of as it's inheritance path. Here's an example:

```lua
local Modern = require 'modern'
local Enemy  = Modern:extend()
local Troll  = Enemy:extend()

print(Troll.__name)       -- prints "Troll"
print(Troll.__namespace)  -- prints "Modern\Enemy\Troll"
```

## Examples

### Enemies

In this example we create a simple enemy hierarchy. Notice the call to the parent's `new` function: `self.__super.new(self, x, y)`. If not called, the parent's `new` would be skipped. Our `Gnome` module sets it's own attack power, which will override the `attack` value from `5`  to `10`.

```lua
local Modern = require 'modern'

--

local Enemy = Modern:extend()

function Enemy:new(x, y)
    self.x = x
    self.y = y
    print('Enemy:new', x, y)
end

--

local Gnome = Enemy:extend()

function Gnome:new(x, y, attack)
    self.__super.new(self, x, y) -- call parent `new`
    self.attack = attack
    print(self.__name .. ':new', x, y, attack)
end

function Gnome:strike()
    print(self.__name .. ' strikes for ' .. self.attack)
end
```

**Running the code...**

```bash
$ lua
> gnome = Gnome(70, 80, 10)  # Enemy:new  70, 80
                             # Gnome:new  70, 80, 10
> print(gnome.x, gnome.y)    # 70, 80
> print(gnome.attack)        # 10
> gnome:strike()             # Gnome strikes for 10
```

### Mixins

In this (silly) example we'll show an example using mixins and how conflicting function names are handled.

```lua
local Modern = require 'modern'

--

local M1 = Modern:extend()

function M1:new() print('M1:new') end
function M1:foo() print('M1:foo') end

--

local M2 = Modern:extend()

function M2:new() print('M2:new') end
function M2:foo() print('M2:foo') end

--

local MM = Modern:extend(M1, M2)

function MM:new() print('MM:new') end
function MM:foo() print('MM:foo') end
```

**Running the code...**

```bash
$ lua
> mm = MM() # MM:new
            # M1:new
            # M2:new
> mm:foo()  # MM:foo
            # M1:foo
            # M2:foo
```

Notice how all 3 `foo` functions are called (in order of inclusion).

> **Important:** All `Mixins` and their functions must be declared before adding them via the `extend` function. This is due to how Lua's `__index` and `__newindex` metamethods work ([see here](https://stackoverflow.com/a/18026617)).

### Love2D

[Love2D](https://love2d.org/) is a fantastic framework to get you up and running with graphics, audio, and easy window configurations. This example shows how to use `Modern` to draw multiple layers using `Mixins`.

**First** we'll create a `Player` module including an `AABB` module, which provides axis-aligned bounding box functionality for collision, and in our example, debugging.

```lua
-- player.lua
local Modern = require 'modern'

--

local AABB = Modern:extend()

function AABB:new()
    -- using `Player` variables to create some more
    self.left   = self.x
    self.top    = self.y
    self.right  = self.x + self.width
    self.bottom = self.y + self.height
end

-- ...
-- Really cool, useful functions removed for brevity :p
-- ...

function AABB:draw()
    if self.debug then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.image, self.x, self.y, self.width, self.height)
    end
end

--

local Player = Modern:extend(AABB)

function Player:new(x, y, src)
    local image = love.graphics.newImage(src)
    local w, h  = image:getDimensions( )

    self.x      = x
    self.y      = y
    self.image  = image
    self.scale  = 0.5
    self.width  = w * self.scale
    self.height = h * self.scale
    self.debug  = false
end

function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, self:center())
end

return Player
```

**Next**, using Love2D we draw the `player` instance.

```lua
-- main.lua
local Player = require 'player'
local player

function love.load()
    player = Player(50, 50, 'player.png')
    player.debug = true
end

function love.draw()
    player:draw()
end
```

**Finally**, our reward!

![Screencap](https://raw.githubusercontent.com/skrolikowski/Modern/master/examples/Love2D/screencap.PNG)

## API

### Modern

`__call` - Create new `Module` instance.

`is(obj)` - Checks if `Module` is a (or inherits from)...

`has(obj)` - Checks `Module` for inclusion of a `Mixin`.

`super(obj)` - Fetch super `Module` of current `Module`.

`copy()` - shallow copy (using `rawset`) of `Module`.

`clone()` - Deep copy (including `metatables`) of `Module`.

`extend(...)` - Extend from another `Module` inheriting all it's goodies.

#### Notable Metamethods

`__tostring()` - Visualization  of `Module` showing properties.

```bash
$ lua
> print(MyExampleModule)
# ---------------------------------------------------------------------------
# | [ ]  | Module  | Namespace         | DataType  | Key     | Value        |
---------------------------------------------------------------------------
# | [-]  | Orc     | Modern\Enemy\Orc  | number    | attack  | 100          |
# | [-]  | Orc     | Modern\Enemy\Orc  | function  | new     | <function>   |
# | [-]  | Orc     | Modern\Enemy\Orc  | number    | y       | 2            |
# | [-]  | Orc     | Modern\Enemy\Orc  | number    | x       | 1            |
# | [-]  | Orc     | Modern\Enemy\Orc  | number    | health  | 100          |
# | [^]  | Enemy   | Modern\Enemy      | function  | new     | <function>   |
# | [-]  | Modern  | Modern            | function  | extend  | <function>   |
# | [-]  | Modern  | Modern            | function  | copy    | <function>   |
# | [-]  | Modern  | Modern            | function  | super   | <function>   |
# | [-]  | Modern  | Modern            | function  | clone   | <function>   |
# | [-]  | Modern  | Modern            | function  | has     | <function>   |
# | [-]  | Modern  | Modern            | function  | is      | <function>   |
# | [+]  | Health  | Modern\Health     | function  | new     | <function>   |
# | [+]  | Health  | Modern\Health     | function  | heal    | <function>   |
# | [+]  | Health  | Modern\Health     | function  | hit     | <function>   |
# | [+]  | Combat  | Modern\Combat     | function  | defend  | <function>   |
# | [+]  | Combat  | Modern\Combat     | function  | new     | <function>   |
# | [+]  | Combat  | Modern\Combat     | function  | hit     | <function>   |
# ---------------------------------------------------------------------------
```

> Note: `[-]` normal property, `[^]` - overridden property, `[+]` - mixin function

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


