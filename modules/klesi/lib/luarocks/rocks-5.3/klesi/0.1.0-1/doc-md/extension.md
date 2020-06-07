**Extension** allows you to create a new class that expands on the features of a base class.

## Example

```lua
local Object = require("klesi")
local Foo = Object:extend()
local Bar = Object:extend()

function Foo:setx(x)
  self.x = x
end

function Foo:getx()
  return self.x
end

function Bar:setx(x)
  self.x = x * 20
end

local obj1 = Foo()
local obj2 = Bar()

obj1:setx(10)
obj2:setx(10)

print(obj1:getx()) --> 10
print(obj2:getx()) --> 20
```