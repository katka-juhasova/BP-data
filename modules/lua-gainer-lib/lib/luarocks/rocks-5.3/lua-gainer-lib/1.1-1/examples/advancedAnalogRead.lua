local gainer = require 'gainer'

---
-- More advanced example for reading analog input on gainer device.

local board = gainer.new()

local function setup()
  board:init()
  board:setSamplingMode(gainer.AIN_ONLY) --or ALL_PORTS
end

local function loop()
  board:setGain(gainer.VSS, 1)
  print("Minimum gain, VSS reference:", board:analogRead(1))
  board:setGain(gainer.VSS, 16)
  print("Maximum gain, VSS reference:",board:analogRead(1))
  board:setGain(gainer.AGND, 1)
  print("Minimum gain, AGND reference:", board:analogRead(1))
  board:setGain(gainer.AGND, 16)
  print("Maximum gain, AGND reference:",board:analogRead(1))
  board:wait(1) -- Wait 1 second to not spam console
end

board:start(setup, loop)