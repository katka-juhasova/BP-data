local bit32 = require 'bit32'
local I2C = require 'periphery'.I2C
local socket = require 'socket'

-- convert to 12-bit signed value
local function conversionValue(low, high)
  local value = bit32.bor(
    bit32.lshift(bit32.band(high, 0xff), 4),
    bit32.rshift(bit32.band(low, 0xff), 4)
  )
  if bit32.band(value, 0x800) ~= 0 then
    value = value - bit32.lshift(1, 12)
  end
  return value
end

local M = {
  Config = {
    CompActiveHigh = 0x0008,
    CompLatching   = 0x0004,
    CompQue = {
      [1] = 0x0000,
      [2] = 0x0001,
      [4] = 0x0002
    },
    CompQueueDisable = 0x03,
    CompWindow       = 0x10,
    DataRate = {
      [ 128] = 0x00,
      [ 250] = 0x20,
      [ 490] = 0x40,
      [ 920] = 0x60,
      [1600] = 0x80,
      [2400] = 0xa0,
      [3300] = 0xc0
    },
    DefaultDataRate  = 1600, -- datasheet p19, config register DR bit default
    Gain = {
      [2/3] = 0x0000,
      [  1] = 0x0200,
      [  2] = 0x0400,
      [  4] = 0x0600,
      [  8] = 0x0800,
      [ 16] = 0x0a00 
    },
    Mode = {
      Continuous = 0x0000,
      Single     = 0x0100
    },
    MuxOffset    = 12,
    OS_Single    = 0x8000,
    PGA_Range = {
      [2/3] = 6.144,
      [  1] = 4.096,
      [  2] = 2.048,
      [  4] = 1.024,
      [  8] = 0.512,
      [ 16] = 0.256
    } 
  },
  DefaultAddress = 0x48,
  MemoryMap = {
    Conversion    = 0x00,
    Config        = 0x01,
    LowThreshold  = 0x02,
    HighThreshold = 0x03
  }
}

function M.read(i2c, device, mux, gain, dataRate, mode)
  local gainFlag = M.Config.Gain[gain]
  assert(gainFlag ~= nil) -- gain must be one of: 2/3, 1, 2, 4, 8, 16
  dataRate = dataRate or M.Config.DefaultDataRate
  local dataRateFlag = M.Config.DataRate[dataRate]
  assert(dataRateFlag ~= nil)
  local config = M.Config.OS_Single
  config = bit32.bor(config, bit32.lshift(bit32.band(mux, 0x07), M.Config.MuxOffset))
  config = bit32.bor(config, gainFlag)
  config = bit32.bor(config, mode)
  config = bit32.bor(config, dataRateFlag)
  config = bit32.bor(config, M.Config.CompQueueDisable) -- disable comparator mode
  
  -- start the ADC conversion
  local msg = {M.MemoryMap.Config, bit32.band(bit32.rshift(config,8), 0xff), bit32.band(config, 0xff)}
  i2c:transfer(device, {msg})
  
  -- wait for the sample to finish based on sample rate plus 0.1 millisecond
  socket.sleep(1 / dataRate + 0.0001)
  
  -- retrieve the result
  local req, res = {M.MemoryMap.Conversion}, {0,0, flags=I2C.I2C_M_RD}
  i2c:transfer(device, {req, res})
  local low, high = res[2], res[1]
  return conversionValue(low, high)
end

function M.readContinuousValue(i2c, device)
  local req, res = {M.MemoryMap.Conversion}, {0,0, flags=I2C.I2C_M_RD}
  i2c:transfer(device, {req, res})
  local low, high = res[2], res[1]
  return conversionValue(low, high)
end

function M.readSingleValue(i2c, device, channel, gain, dataRate)
  return M.read(i2c, device, channel + 0x04, gain, dataRate, M.Config.Mode.Single)
end

function M.startContinuous(i2c, device, channel, gain, dataRate)
  return M.read(i2c, device, channel + 0x04, gain, dataRate, M.Config.Mode.Continuous)
end

function M.stopContinuous(i2c, device)
  local config = 0x8583
  local req = {M.MemoryMap.Config, bit32.band(bit32.rshift(config,8), 0xff), bit32.band(config, 0xff)}
  i2c:transfer(device, {req})
end

function M.toVoltage(value, gain)
  return value * M.Config.PGA_Range[gain] / 2047
end

return M
