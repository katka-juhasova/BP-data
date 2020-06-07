
local Object = require("klesi")
local Point = Object:extend()

function Point:new(x, y)
  self.x, self.y = x, y
end


function Point:__tostring()
  return "(".. self.x ..", ".. self.y ..")"
end

function Point:__concat(val)
  return tostring(self) .. ", " .. tostring(val)
end

function Point:__add(val)
  return Point(
      self.x + val.x,
      self.y + val.y)
end

function Point:__sub(val)
  return Point(
      self.x - val.x,
      self.y - val.y
  )
end

function Point:__mul(val)
  return Point(
      self.x * val.x,
      self.y * val.y
  )
end

function Point:__div(val)
  return Point(
      self.x / val.x,
      self.y / val.y
  )
end

function Point:__mod(val)
  return Point(
      self.x % val.x,
      self.y % val.y
  )
end

function Point:__pow(val)
  return Point(
      self.x ^ val.x,
      self.y ^ val.y
  )
end

function Point:__unm()
  return Point( -self.x, -self.y )
end

function Point:__eq(val)
  return
      self.x == val.x and
      self.y == val.y
end

-- lt and le makes no sense in a 2D array.

local p1 = Point(1, 2)
local p2 = Point(3, 4)
local p3 = p1 + p2

assert(p1 + p2 == p3)
assert(p1 == p3 - p2)
assert(p2 == p3 - p1)
assert(p1 ~= p3)
assert(p1 * p2 == Point(1*3, 2*4))
assert(p1 ^ p2 == Point(1^3, 2^4))
assert(p1 / p2 == Point(1/3, 2/4))
assert(p1 .. p2 == "(1, 2), (3, 4)")
assert(-p1 == Point(-1, -2))
assert(p3 % p1 == Point(4 % 1, 6 % 2))

