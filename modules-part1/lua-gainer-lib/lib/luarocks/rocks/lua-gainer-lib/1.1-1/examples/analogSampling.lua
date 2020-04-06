local gainer = require 'gainer'

---
-- Simple example for analog sampling in continuous mode on gainer device.

local board = gainer.new()

local function buttonInterrupt()
  if board.continousMode.status then
    board:endSampling()
  end
end

local function setup()
  board:init()
  board:attatchInterrupt("button", buttonInterrupt)
  board:beginAnalogSampling()
end

local function loop()
  if board.continousMode.status then
    print("Sample:", board:getSample(1,2,3,4))
  board:wait(1)
  else
    os.exit()
  end
end

board:start(setup, loop)