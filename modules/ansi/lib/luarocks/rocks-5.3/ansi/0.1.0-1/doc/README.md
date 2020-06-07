
# lua-ANSI

Control your terminal with Lua!

For complete documentation, [visit the wiki!](doc-md/home.md)

## Installation

lua-ansi is uploaded on [Luarocks](https://luarocks.org). To install, simply go
to your favorite terminal and issue the following command:

```shell
$ luarocks install ansi # --local
```

## Quick-Start by Example

```lua
local ansi = require("ansi")

-- Since I'll be doing a lot of commands, I'll need to
-- unload then on _G.
for k,v in pairs(ansi) do
  _G[k] = v
end


-- Writing it directly on the terminal
setColor(red, layers.fg, io.stdout)
setCGA(cga.bold, io.stdout)
print("Hello, World!")

moveDown(3, io.stdout)


-- Writing it as part of a message
local message =
    setColor(red, layers.fg) ..
    setCGA(cga.underline) ..
    "Hello World!"
print(message)
```

