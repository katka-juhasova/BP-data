# lua-string-trim

strip the space at both ends of string.

---

## Installation

```sh
luarocks install string-trim --from=http://mah0x211.github.io/rocks/
```

## Function

### str = trim( str )

returns the string stripped of whitespace from both ends.

**Parameters**

- `str:string`: string.

**Returns**

- `str:string`: string.


## Usage

```lua
local trim = require('string.trim')
-- you must install dump module from https://github.com/mah0x211/lua-dump 
-- or luarocks install dump
local dump = require('dump') 

print( dump( trim('    hello world!      ') ) )
-- "hello world!"
