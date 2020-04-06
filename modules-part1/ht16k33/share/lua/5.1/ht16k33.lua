local bit32 = require 'bit32'

local M = {
  BlinkRate = {
    [      'OFF'] = 0x00,
    ['DISPLAYON'] = 0x01,
    [  'HALF_HZ'] = 0x06,
    [     '1_HZ'] = 0x04,
    [     '2_HZ'] = 0x02
  },
  Command = {
    SYSTEM_SETUP = 0x20,
    BLINK        = 0x80,
    BRIGHTNESS   = 0xe0
  },
  DEVICE = 0x70,
  OSCILLATOR = 0x01
}

function M.newMatrix8x8(i2c, device)
  local matrix_8x8 = require 'ht16k33.matrix_8x8'
  return matrix_8x8.new(i2c, device)
end

function M.setBlink(i2c, device, rateFlag)
  local msgs = {{bit32.bor(M.Command.BLINK, M.BlinkRate.DISPLAYON, rateFlag)}}
  i2c:transfer(device or M.DEVICE, msgs)
end

function M.setBrightness(i2c, device, brightness)
  assert(brightness >= 0 and brightness <= 15)
  local msgs = {{bit32.bor(M.Command.BRIGHTNESS, brightness)}}
  i2c:transfer(device or M.DEVICE, msgs)
end

function M.writeBuffer(i2c, device, buffer)
  device = device or M.DEVICE
  for i, value in pairs(buffer) do
    local register = i-1
    local msgs = {{register, value}}
    i2c:transfer(device, msgs)
  end
end

return M
