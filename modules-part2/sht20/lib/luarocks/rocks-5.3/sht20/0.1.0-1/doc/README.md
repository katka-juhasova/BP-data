<img align="right" src="sht20.jp2" width="120">

# SHT20 Lua driver

A sensor driver for the Comimark SHT20 industrial atmospheric sensor.

## Installing

You can use the Lua module from within a Go app via [gluaperiphery](https://github.com/nubix-io/gluaperiphery).

## Using

### Configuring a modbus connection

```lua
local modbus = require 'periphery.modbus'

local opts = {
  device   = '/dev/tty.SLAB_USBtoUART',
  baudRate = 9600,
  dataBits = 8,
  parity   = 'N',
  stopBits = 1,
  slaveId  = 0x01,
  timeout  = 1.0 
}
local modbusClient = modbus(opts)
...
```

### Taking a temperature reading

```lua
local sht20 = require 'sht20.modbus'

local tempC = sht20.readTemperatureC(modbusClient)
print(string.format('temp = %3.1f C', tempC))
```

Sample output:

```
temp = 63.6 C
```

### Taking a humidity reading

```lua
local sht20 = require 'sht20.modbus'

local humRH = sht20.readHumidityRH(modbusClient)
print(string.format('humidity = %3.1f %% RH', humRH))
```

Sample output:

```
humidity = 67.1 % RH
```
