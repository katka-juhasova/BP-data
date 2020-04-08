# Cloning

**Cloning** creates a duplicate of your object. This is implemented in the `Object`'s `:clone()` command.

```lua
local Object = require("klesi")
local Foo = Object:extend()

function Foo:setx(x)
  self.x = x
end

function Foo:getx()
  return self.x
end

local obj1 = Foo()
obj1:setx(10)

local obj2 = obj1:clone()
print(obj2:getx()) --> 10

obj2:setx(15)
print(obj2:getx()) --> 15
print(obj1:getx()) --> 10; obj2 does not affect obj1 since it is a separate object.
```