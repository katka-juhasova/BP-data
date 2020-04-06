local gainer = require 'gainer'

---
-- Simple example for blinking on-board LED on gainer device.

local board = gainer.new()

local function setup()

  ---
  -- Default port is /dev/ttyUSB0 and default configuration is 1
  -- if your serial port adress is different (for example /dev/ttyUSB1
  -- you can use:
  --   board:init("/dev/ttyUSB0")
  -- or even set other configuration as default:
  --   board:init("/dev/ttyUSB0", 2)

  board:init()
end


local function loop()
  board:digitalWrite(gainer.HIGH, gainer.LED)
  board:wait(1)
  board:digitalWrite(gainer.LOW, gainer.LED)
  board:wait(1)
end

board:start(setup, loop)