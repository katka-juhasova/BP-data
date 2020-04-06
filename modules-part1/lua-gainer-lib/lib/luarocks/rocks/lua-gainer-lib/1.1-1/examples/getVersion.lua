local gainer = require 'gainer'

---
-- Simple example that prints version number of firmware on gainer device.

local board = gainer.new()

local function setup()
  board:init(nil, 0) -- Firmware version can be only checked in configuration 0
  print("Firmware version: ", board:getVersion())
end

local function loop()
  os.exit() -- Just terminate the program
end

board:start(setup, loop)