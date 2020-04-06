# CodeGen.lpeg

---

# Reference

Just an alternate implementation using
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html)
(instead of pattern matching from 
[string](http://www.lua.org/manual/5.1/manual.html#5.4.1) library).

# Examples

```lua
local CodeGen = require 'CodeGen.lpeg'

tmpl = CodeGen {    -- instanciation
    tarball = "${name}-${version}.tar.gz",
    name = 'lua',
}
tmpl.version = 5.1
output = tmpl 'tarball'     -- interpolation
print(output) --> lua-5.1.tar.gz
```
