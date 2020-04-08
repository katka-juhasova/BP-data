lua-tointeger
=========

string to integer conversion module.

---

## Installation

```
$ luarocks install tointeger --from=http://mah0x211.github.io/rocks/
```


## Usage


```lua
local tointeger = require('tointeger')

print( tointeger('123') == 123 )
print( tointeger('-123') == -123 )
```

