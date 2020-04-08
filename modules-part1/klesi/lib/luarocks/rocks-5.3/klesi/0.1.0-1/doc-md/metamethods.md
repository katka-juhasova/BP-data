# Metamethods

**Metamethods** allows an object to use syntatically simple operators such as `+`, `-`, `*`, `==`, and others.

## Example

```lua
local Object = require("klesi")
local Point = Object:extend()

function Point:new(x, y)
  self.x, self.y = x, y
end

function Point:__tostring()
  return "(".. self.x ..", ".. self.y ..")"
end

function Point:__add(val)
  return Point(
      self.x + val.x,
      self.y + val.y
  )
end

function Point:__sub(val)
  return Point(
      self.x - val.x,
      self.y - val.y
  )
end

function Point:__eq(val)
  return self.x == val.x and self.y == val.y
end


local p1 = Point(1, 3)
local p2 = Point(2, 5)
local p3 = p1 + p2

print(p1, p2) --> (1, 3)        (2, 5)
print(p1 + p2) --> (3, 8)
print(p3 - p1 == p2) --> true
print(p1 ~= p2) --> true
print(p2 == p3) --> false
```

## List of Supported Metamethods

While most metamethods are supported, a few, such as `__index` and `__metatable` can cause the program to break. Here is a list of metamethods declared to be safe:

### Arithmetical
* `__add(val)` - `self + val`
* `__sub(val)` - `self - val`
* `__mul(val)` - `self * val`
* `__div(val)` - `self / val`
* `__mod(val)` - `self % val`
* `__pow(val)` - `self ^ val`
* `__unm()` - `-self`

### Logic
* `__eq(val)` - `self == val`
* `__lt(val)` - `self < val`
* `__le(val)` - `self <= val`

### Misc
* `__concat(val)` - `self .. val`
* `__tostring()` - `tostring(self)`
* `__call(...)` - `self(...)`