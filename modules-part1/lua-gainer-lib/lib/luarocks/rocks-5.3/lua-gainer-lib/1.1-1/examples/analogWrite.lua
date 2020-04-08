local gainer = require 'gainer'

---
-- Simple example for writing analog output on gainer device.

local board = gainer.new()

local function setup()
  board:init()
end

local function loop()
  -- On gainer device, writing to only 1 output like this:
  board:analogWrite(gainer.SINGLE, 1, 123)
  board:wait(1)
  -- uses different command than writing to multiple outputs like this:
  board:analogWrite(gainer.MULTI, 56, 44, 255, 5)
  board:wait(1)
  -- but both methods can be used.
  -- It is possible to only preserve inputs like this:
  board:analogWrite(gainer.MULTI, 56, nil, nil, 5)
  board:wait(1)
  board:analogWrite(gainer.MULTI, 0, 0, 0, 0) -- setting analog 0 - no voltage
  board:wait(1)
end

board:start(setup, loop)