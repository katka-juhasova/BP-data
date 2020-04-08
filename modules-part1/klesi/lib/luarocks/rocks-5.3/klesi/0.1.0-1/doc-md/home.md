# Klesi

## Install

Klesi is uploaded to [Lua Rocks][1]. Assuming you have `luarocks` installed, simply type:

```shell
$ luarocks install klesi # --local if you want to install it locally
```

## Quick Example

```lua
local Object = require("klesi")
local Foo = Object:extend()
local Bar = Foo:extend()

function Foo:new(x)
  self:setx(x)
end

function Foo:setx(x)
  self.x = x
end

function Foo:getx()
  return self.x
end


function Bar:setx(x)
  self.x = x * 2
end

local obj1 = Foo(10)
local obj2 = Bar(10)

print(obj1:getx()) --> 10
print(obj2:getx()) --> 20
```

## Features
* [Extension](extension.md) - The foundation of polymorphism; create classes that expand on base classes.
* [Cloning](cloning.md) - Create duplicates of your objects
* [Casting](casting.md) - Create lower-level forms of your objects
* [Metamethods](metamethods.md) - Use lua's [metamethods][2] to improve your classes.

  [1]: https://luarocks.org
  [2]: http://lua-users.org/wiki/MetatableEvents
