
# Test.Builder

---

# Reference

This module is the _core_ of the framework.
It allows its extensibility.

All libraries built with `Test.Builder` could work together.

See the module
[Test.LongString](http://fperrad.github.com/lua-TestLongString/)
as a real example.

Note : this kind of library could be tested
with the help of the module `Test.Builder.Tester`.

# Examples

This minimal example shows how to add a function/predicate `iszero`.

```lua
-- iszero.lua
local tb = require 'Test.Builder'.new()  -- it's a singleton shared by all libraries

function _G.iszero(val, name)
    local pass = val == 0
    tb:ok(pass, name)
    if not pass then
        tb:diag("         got: " .. tostring(val))
    end
end
```

```lua
-- iszero.t
require 'Test.More'
require 'iszero'

plan(1)

val = 0
iszero(val, "val is zero")
```

```
$ lua iszero.t
1..1
ok 1 - val is zero
```
