
local Object = require("klesi")

local Foo = Object:extend()

function Foo:new(x)
  self:setx(x)
end

function Foo:setx(x)
  self.x = x
end

function Foo:getx()
  return self.x
end


local Bar = Foo:extend()
function Bar:setx(x)
  self.x = x * 2
end

local obj1 = Foo(10)
local obj2 = Bar(10)

assert( obj1:getx() == 10 )
assert( obj2:getx() == 20 )
