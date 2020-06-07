Stringify lua
=======

Converting lua table to string


```Lua
require "stringify"

print(table.stringify({["foo"] = "bar", [123] = 456})) -- {[123]=456,foo="bar"}
```
