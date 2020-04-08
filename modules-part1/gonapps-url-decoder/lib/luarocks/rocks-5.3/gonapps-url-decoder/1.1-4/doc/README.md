gonapps-url-decoder
=

## About
An url decoder for lua
## Usage
**installation**
```bash
$ sudo luarocks install gonapps-url-decoder
```
**example code**
```lua
local urlDecoder = require "gonapps.url.decoder"
print(urlDecoder.rawDecode(url))
print(urlDecoder.decode(url))
```
## License
Mozilla Public License 2.0
