gonapps-cookie
=

## About
Cookie for lua
## Usage
**installation**
```bash
$ sudo luarocks install gonapps-cookie
```
**example code**
```lua
local cookieModule = require "gonapps.cookie"
local cookie = cookieModule.new("aaa=bbb; ccc=ddd; HttpOnly")
if cookie.flags["HttpOnly"] then
    print("HTTP Only Flag")
end
print("ccc", cookie.data["ccc"])
print(cookie:toString())
```
## License
Mozilla Public License 2.0
