<img align="right" src="adxl345.png" width="70">

# ADXL345 Lua driver

A [lua-periphery](https://github.com/vsergeev/lua-periphery) based sensor driver for the ADXL345 3-axis accelerometer.

## Installing

If you are on Linux:

```sh
$ luarocks install adxl345
```

Otherwise, you can use the Lua module from within a Go app via [glua-periphery](https://github.com/BixData/gluaperiphery).

## Using

### Taking a reading

```lua
local adxl345 = require 'adxl345'
local periphery = require 'periphery'

local i2c = periphery.I2C('/dev/i2c-1')
adxl345.enableMeasurement(i2c)
local x,y,z = adxl345.readAcceleration(i2c)

print(string.format('x = %2.3f', x))
print(string.format('y = %2.3f', y))
print(string.format('z = %2.3f', z))
```

Sample output:

```
x = -0.028 G
y = 0.060 G
z = 1.036 G
```

### Configuring measurement range

```lua
adxl345.setRange(i2c, adxl345.Range['2_G'])
adxl345.enableMeasurement(i2c)
...
```

Valid values are `2_G`, `4_G`, `8_G`, and `16_G`.

### Configuring bandwidth rate

```lua
adxl345.setBandwidthRate(i2c, adxl345.BandwidthRate['100_HZ'])
adxl345.enableMeasurement(i2c)
...
```

Valid values are `3200_HZ`, `1600_HZ`, `800_HZ`, `400_HZ`, `200_HZ`, `100_HZ`, `50_HZ`, `25_HZ`, `12_5_HZ`, `6_25_HZ`, `3_13_HZ`, `1_56_HZ`, `0_78_HZ`, `0_39_HZ`, `0_20_HZ`, `0_10_HZ`.
