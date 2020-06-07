# Casting

**Casting** allows an object to easily interact with the methods of one of its super classes.

## Example

```lua
local Object = require("klesi")
local Foo = Object:extend()
local Bar = Foo:extend()

function Foo:setx(x)
  self.x = x
end

function Foo:getx()
  return self.x
end

function Bar:getx()
  return self.x * 2
end


local obj = Bar()
obj:setx(10)

print( obj:getx() ) --> 20
print( obj:cast(Foo):getx() ) --> 10
```