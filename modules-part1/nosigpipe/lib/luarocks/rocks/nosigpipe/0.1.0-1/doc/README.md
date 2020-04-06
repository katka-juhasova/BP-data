# lua-nosigpipe

a module that ignore SIGPIPE.

## Installation

```sh
luarocks install --from=http://mah0x211.github.io/rocks/ nosigpipe
```

## Usage

Ignore the SIGPIPE automatically when this module has been loaded.

```
local ok = require('nosigpipe')
if not ok then
    print('SIGPIPE is not supported on this platform')
end
```

