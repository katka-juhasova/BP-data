local gainer = require 'gainer'

---
-- Simple example for using 8x8 LED Matrix with GAINER device.

local board = gainer.new()

local checkerboardA = {
0x0F0F0F0F,
0xF0F0F0F0,
0x0F0F0F0F,
0xF0F0F0F0,
0x0F0F0F0F,
0xF0F0F0F0,
0x0F0F0F0F,
0xF0F0F0F0
}

local checkerboardB = {
0xF0F0F0F0,
0x0F0F0F0F,
0xF0F0F0F0,
0x0F0F0F0F,
0xF0F0F0F0,
0x0F0F0F0F,
0xF0F0F0F0,
0x0F0F0F0F
}

local function setup()
  board:init(nil, 7)
end

local function loop()
  --There are two ways to set MED Matrix: by setMatrix function like this:
  board:setMatrix(checkerboardA)
  board:wait(1)
  --Or by simple for loop and analogWrite function like this:
  for i, value in ipairs(checkerboardB) do
    board:analogWrite(gainer.SINGLE, i, value)
  end
  --Second option is slower and flickering can be seen.
  board:wait(1)
end

board:start(setup, loop)