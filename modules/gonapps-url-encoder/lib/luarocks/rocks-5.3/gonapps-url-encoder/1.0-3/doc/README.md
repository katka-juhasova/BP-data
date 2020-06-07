gonapps-url-encoder
=

## About
An url encoder for lua
## Usage
**installation**
```bash
$ sudo luarocks install gonapps-url-encoder
```
**example code**
```lua
local urlEncoder = require "gonapps.url.encoder"
print(urlEncoder.rawEncode(url))
print(urlEncoder.encode(url))
```
## License
Mozilla Public License 2.0
