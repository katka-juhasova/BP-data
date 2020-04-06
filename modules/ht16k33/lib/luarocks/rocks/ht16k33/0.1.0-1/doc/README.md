<img align="right" src="ht16k33.png" width="70">

# HT16K33 Lua driver

A [lua-periphery](https://github.com/vsergeev/lua-periphery) based sensor driver for the HT16K33 LED matrix controller.

## Installing

If you are on Linux:

```sh
$ luarocks install ht16k33
```

Otherwise, you can use the Lua module from within a Go app via [glua-periphery](https://github.com/BixData/gluaperiphery).

## Using 8x8 Matrix API

A matrix facade encapsulates a 16-byte display buffer and provides buffer accessors for drawing pixels using convenient [x,y] coordinates. Calling the matrix `write()` function transfers the buffer to the HT16K33.

### Construct matrix facade for default device 0x70

```lua
local ht16k33 = require 'ht16k33'
local periphery = require 'periphery'

local i2c = periphery.I2C('/dev/i2c-1')
local matrix = ht16k33.newMatrix8x8(i2c, nil)
```

### Construct matrix facade for device 0x71

```lua
local ht16k33 = require 'ht16k33'
local periphery = require 'periphery'

local i2c = periphery.I2C('/dev/i2c-1')
local matrix = ht16k33.newMatrix8x8(i2c, 0x71)
```

### Turn on all LEDs (8x8)

```lua
for y = 0,7 do
  for x = 0,7 do
    matrix:setPixel(x,y,true)
  end
end
matrix:write()
```

### Turn off all LEDs

```lua
matrix:clear()
matrix:write()
```

### Set brightness to 50%

```lua
matrix:setBrightness(7)
```

### Setup blinking display

```lua
matrix:setBlink(ht16k33.BlinkRate.2_HZ)
```

## Using Raw API

### Turn on oscillator

```lua
local ht16k33 = require 'ht16k33'
local periphery = require 'periphery'

local i2c = periphery.I2C('/dev/i2c-1')
local msgs = {{bit32.bor(ht16k33.Command.SYSTEM_SETUP, ht16k33.OSCILLATOR)}}
i2c:transfer(device, msgs)
```

### Turn on display

```lua
local ht16k33 = require 'ht16k33'
local periphery = require 'periphery'

local i2c = periphery.I2C('/dev/i2c-1')
ht16k33.setBlink(i2c, device, ht16k33.BlinkRate.OFF)
```

### Turn on all LEDs

```lua
local buf = {}
for i=1,16 do buf[#buf+1] = 0xff end
ht16k33.writeBuffer(i2c, nil, led, buf)
```

### Turn off all LEDs

```lua
ht16k33.writeBuffer(i2c, nil, {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
```

### Set brightness of default device 0x70

```lua
ht16k33.setBrightness(i2c, nil, 7)
```

### Set brightness of device 0x71

```lua
ht16k33.setBrightness(i2c, 0x71, 7)
```

### Setup blinking display

```lua
ht16k33.setBlink(i2c, nil, ht16k33.BlinkRate.2_HZ)
```
