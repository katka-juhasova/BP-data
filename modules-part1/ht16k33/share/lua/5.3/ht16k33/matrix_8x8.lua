local bit32 = require 'bit32'
local ht16k33 = require 'ht16k33'

local M = {}

function M.new(i2c, device)
  device = device or ht16k33.DEVICE
  local self = {
    buffer = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    device = device,
    i2c    = i2c
  }
  
  -- Inherit module functions
  for k,v in pairs(M) do self[k] = v end
  
  -- Turn on oscillator
  local msgs = {{bit32.bor(ht16k33.Command.SYSTEM_SETUP, ht16k33.OSCILLATOR)}}
  i2c:transfer(device, msgs)

  -- Set full brightness
  ht16k33.setBrightness(i2c, device, 15)

  -- Turn on display
  ht16k33.setBlink(i2c, device, ht16k33.BlinkRate.OFF)
  
  return self
end

function M:clear()
  for i=1,#self.buffer do self.buffer[i]=0 end
end

function M:setBlink(rateFlag)
  ht16k33.setBlink(self.i2c, self.device, rateFlag)
end

function M:setBrightness(brightness)
  ht16k33.setBrightness(self.i2c, self.device, brightness)
end

-- Set a given LED to ON or OFF
-- @param led the LED number (valid values are 0..127)
-- @value true or false
function M:setLED(led, value)
  local pos = 1 + math.floor(led / 8)
  local offset = led % 8
  if value == true then
    self.buffer[pos] = bit32.bor(self.buffer[pos], bit32.lshift(1, offset))
  else
    self.buffer[pos] = bit32.band(self.buffer[pos], bit32.bnot(bit32.lshift(1, offset)))
  end
end

function M:setPixel(x, y, value)
  local led = y*16 + (x+7) % 8
  self:setLED(led, value)
end

function M:write()
  ht16k33.writeBuffer(self.i2c, self.device, self.buffer)
end

return M
