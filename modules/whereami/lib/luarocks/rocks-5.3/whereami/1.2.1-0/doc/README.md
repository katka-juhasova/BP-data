# lua-whereami

A Lua binding to the [whereami library](https://github.com/gpakosz/whereami).

## Usage

```lua

local whereami = require('whereami')

local exe, err = whereami()
-- exe will contain path to the lua interpreter
```

## Licensing

This binding is under the MIT license (see `LICENSE`)

The original C library is released under the WTFPLV2 license.
