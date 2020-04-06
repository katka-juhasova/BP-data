local gainer = require 'gainer'

---
-- Another example for using 8x8 LED Matrix with GAINER device.

local board = gainer.new()

local buffer = {}
local line = ""

local function setup()
  board:init(nil, 7)
end

local function loop()

  for i = 1, 8 do
    for j = 1, 8 do
      local noise = math.random(0, 15)
      line = line .. string.format("%x", noise)
    end
    buffer[i] = tonumber("0x" .. line)
    line = ""
  end

  board:setMatrix(buffer)
  gainer.sleep(0.06) -- Reduce flickering
end

board:start(setup, loop)