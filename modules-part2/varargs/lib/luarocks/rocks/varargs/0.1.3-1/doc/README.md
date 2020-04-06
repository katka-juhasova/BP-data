
## Varargs
Friendly tuple manipulation

[Jump to Reference](#reference)

### Installation

Varargs uses **luarocks**! To install, simply type:

```bash
$ luarocks install varargs # --local
```

### Quick-Start

```lua
local vargs = require("varargs")

-- Let's do something simple:
-- This returns two numbers:
-- The quotient (as a whole number),
-- and the remainder.
local function intdiv(x, y)
  return math,floor(x/y), x % y
end


-- This returns 5/2 with intdiv.
local a = function() return intdiv(5, 2) end

-- And this only gives errors.
local b = function() return nil * 5 end

print( vargs.fst(a()) ) --> 2, 5/2 = 2
print( vargs.last(a())  ) --> 1, 5%2 = 1

-- index gives all but the last
print( vargs.index(1, 2, 3, 4, 5) ) --> 1    2    3    4

-- tail gives all but the first
print( vargs.tail(1, 2, 3, 4, 5) )  --> 2    3    4    5

-- There's also the shortcuts second and third.
print( vargs.snd(1, 2, 3)  ) --> 2
print( vargs.thrd(1, 2, 3) ) --> 3


```

### Reference

* `fst(...)` - Alias for {...}[1]
* `snd(...)` - Alias for {...}[2]
* `thrd(...)` - Alias for {...}[3]
* `last(...)` - Returns last value
* `tail(...)` - Returns all values except the first
* `index(...)` - Returns all values except the last
