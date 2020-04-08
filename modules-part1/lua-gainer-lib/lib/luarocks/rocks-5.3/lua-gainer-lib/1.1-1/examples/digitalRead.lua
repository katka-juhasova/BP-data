local gainer = require 'gainer'

---
-- Simple example for reading digital input on gainer device.

local board = gainer.new()

local function setup()
  board:init()
end

local function loop()
  -- On gainer device, reading only 1 input like this:
  print("Single input:", board:digitalRead(1))
  -- uses different command than reading multiple inputs like this:
  print("Multiple input:", board:digitalRead(1, 2, 3, 4))
  -- but both methods can be used.

  board:wait(1) -- Wait 1 second to not spam console
end

board:start(setup, loop)