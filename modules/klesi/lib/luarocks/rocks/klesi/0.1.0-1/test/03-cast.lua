
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
  return self.super.getx(self) * 2
end


local obj = Bar()
obj:setx(10)

assert( obj:getx() == 20 )
assert( obj:cast(Foo):getx() == 10 )

