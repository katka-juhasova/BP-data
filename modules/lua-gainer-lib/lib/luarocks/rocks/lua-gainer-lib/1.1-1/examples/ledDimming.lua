local gainer = require 'gainer'

---
-- Simple example for LED diode dimming via potentiometer
-- using analogRead and analogWrite on gainer device.
-- Commection diagram:
-- LED pin to aout 0
-- Edge Pins of potentiometer to 5V and GND
-- Middle pin of potentiometer to ain 0

local board = gainer.new()

local result = 0

local function setup()
  board:init()
end

local function loop()
  result = board:analogRead(1)
  board:analogWrite(gainer.SINGLE, 1, result)
end

board:start(setup, loop)