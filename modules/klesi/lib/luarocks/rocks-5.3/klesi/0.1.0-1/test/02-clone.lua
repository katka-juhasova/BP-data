
local Object = require("klesi")

local Foo = Object:extend()

function Foo:new(x)
  self:setx(x)
  self.count = 0
end

function Foo:setx(x)
  self.x = x
end

function Foo:getx()
  self.count = self.count + 1
  return self.x
end

function Foo:getcount()
  return self.count
end


local obj1 = Foo(10)
local obj2 = obj1:clone()

obj2:setx(15)

assert( obj1:getx()     == 10 )
assert( obj2:getcount() == 0  )
assert( obj2:getx()     == 15 )
assert( obj1:getcount() == 1  )

