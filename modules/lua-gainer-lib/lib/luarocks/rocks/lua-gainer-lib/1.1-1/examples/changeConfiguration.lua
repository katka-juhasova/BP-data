local gainer = require 'gainer'

---
-- Simple example for changing configurations on gainer device.

local board = gainer.new()

local function setup()
  board:init()
end

local function loop()
  -- It takes some time to change between
  -- and current output is set to default state.
  board:setConfiguration(1)
  board:digitalWrite(gainer.HIGH,gainer.LED)
  board:wait(1)
  board:setConfiguration(2)
  board:digitalWrite(gainer.LOW, gainer.LED)
  board:wait(1)
end

board:start(setup, loop)