local gainer = require 'gainer'

---
-- Simple example for writing digital output on gainer device.

local board = gainer.new()

local function setup()
  board:init()
end

local function loop()
  -- On gainer device, writing to only 1 output like this:
  board:digitalWrite(gainer.HIGH, 1)
  board:wait(1)
  -- uses different command than writing to multiple outputs like this:
  board:digitalWrite(gainer.HIGH, 1, 2, 3, 4)
  board:wait(1)
  -- but both methods can be used.
  -- It is possible to set os-board led like this:
  board:digitalWrite(gainer.HIGH, gainer.LED)
  board:wait(1)
  -- or like this:
  board:digitalWrite(gainer.HIGH, 1, 2, gainer.LED, 3)
  board:wait(1)

  board:digitalWrite(gainer.LOW, 1, 2, 3, 4, gainer.LED) -- setting digital low
  board:wait(1)
end

board:start(setup, loop)