
# Mock

---

## Mock Object

`mock` allows to override a method of an object.

`unmock` allows to restore the initial (ie. class) behavior
of a mocked object.

```lua
require 'Coat'

class 'Rectangle'
has.x               = { is = 'rw', isa = 'number', required = true }
has.y               = { is = 'rw', isa = 'number', required = true }

function method:getArea ()
    return self.x * self.y
end

require 'Rectangle'

r = Rectangle{ x = 2, y = 4 }

r:mock('getArea', function () return 42 end)

r:unmock 'getArea'
```

## Mock Class

Create mock class could be simply done with `override`.
All instances (already created and future) are altered.
It is not possible to restore the initial behavior.

The 3 following syntax are equivalent :

```lua
require 'Rectangle'

function Rectangle.override:getArea ()
    return 42
end
```

```lua
require 'Rectangle'

Coat.override(Rectangle, 'getArea', function () return 42 end)
```

```lua
require 'Rectangle'

r = Rectangle{ x = 2, y = 4 }

function r.override:getArea ()
    return 42
end
```
