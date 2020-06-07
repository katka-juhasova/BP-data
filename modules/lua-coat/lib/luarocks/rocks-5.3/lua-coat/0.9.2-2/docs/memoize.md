
# Memoization

---

## Rectangle

```lua
require 'Coat'

class 'Rectangle'
has.x               = { is = 'rw', isa = 'number', required = true }
has.y               = { is = 'rw', isa = 'number', required = true }

function overload:__tostring ()
    return self._CLASS .. ':' .. self.x .. 'x' .. self.y
end

function method:_get_area ()
    return self.x * self.y
end

function method:getWeight (density)
    return self.x * self.y * density
end
memoize 'getWeight'
```

A method could become memoized after its definition.

The memoization is not reversable.

```lua
require 'Rectangle'

Rectangle.memoize '_get_area'
```

All values are memoized in an uniq table `Coat.Meta.Class._CACHE`.
This table uses weak reference.

The key is composed of the name of the method
and the concatenation of stringified parameter (self is the first one).
It is important to define the appropriate `__tostring` for each not basic type.

## Special case : ImmutableRectangle

Computed attribute of immutable object could be implemented with `lazy_build`.

```lua
require 'Coat'

class 'ImmutableRectangle'
extends 'Rectangle'
has.x               = { '+', is = 'ro' }
has.y               = { '+', is = 'ro' }
has.area            = { is = 'ro', lazy_build = true }

function method:_build_area ()
    return self.x * self.y
end
```
