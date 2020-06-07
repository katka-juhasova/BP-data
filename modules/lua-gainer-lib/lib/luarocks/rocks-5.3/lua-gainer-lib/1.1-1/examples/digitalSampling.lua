local gainer = require 'gainer'

---
-- Simple example for digital sampling in continous mode on gainer device.

local board = gainer.new()

local function buttonInterrupt()
  if board.continousMode.status then
    board:endSampling()
  end
end

local function setup()
  board:init()
  board:attatchInterrupt("button", buttonInterrupt)
  board:beginDigitalSampling()
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