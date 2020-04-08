lua-toboolean
=========

string to boolean conversion module.

---

## Installation

```
$ luarocks install toboolean --from=http://mah0x211.github.io/rocks/
```


## Usage


```lua
local toboolean = require('toboolean')

print( toboolean('true') == true )
print( toboolean('false') == false )
```

