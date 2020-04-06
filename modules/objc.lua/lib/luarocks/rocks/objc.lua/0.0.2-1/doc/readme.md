# objc.lua

> Lua ⇆ Objective-C bridge _(experimental)_


## Install

```
$ luarocks install objc.lua
```


## Usage

```lua
local objc = require "objc"

objc.import "Foundation"


local now = objc.NSDate:date()
local localizedDate = objc.NSDateFormatter:localizedStringFromDate_dateStyle_timeStyle_(now, 2, 2)

print(localizedDate)
-- => "10. Sep 2017, 13:22:27"
```


## License

MIT © [Lukas Kollmer](https://lukaskollmer.me)
