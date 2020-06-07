local bit32 = require 'bit32'
local I2C = require 'periphery'.I2C

local M = {
  BandwidthRate = {
    ['3200_HZ'] = 0x0f,
    ['1600_HZ'] = 0x0e,
    [ '800_HZ'] = 0x0d,
    [ '400_HZ'] = 0x0c,
    [ '200_HZ'] = 0x0b,
    [ '100_HZ'] = 0x0a, -- default
    [  '50_HZ'] = 0x09,
    [  '25_HZ'] = 0x08,
    ['12_5_HZ'] = 0x07,
    ['6_25_HZ'] = 0x06,
    ['3_13_HZ'] = 0x05,
    ['1_56_HZ'] = 0x04,
    ['0_78_HZ'] = 0x03,
    ['0_39_HZ'] = 0x02,
    ['0_20_HZ'] = 0x01,
    ['0_10_HZ'] = 0x00
  },
  ConversionFactor = {
    SCALE_MULTIPLIER = 0.004,
    STANDARD_GRAVITY = 9.80665
  },
  DEVICE = 0x53,
  MEASURE = 0x08,
  MemoryMap = {
    BW_RATE     = 0x2c,
    POWER_CTL   = 0x2d,
    DATA_FORMAT = 0x31,
    DATAX0      = 0x32
  },
  Range = {
    ['16_G'] = 0x03,
    [ '8_G'] = 0x02,
    [ '4_G'] = 0x01,
    [ '2_G'] = 0x00
  }
}

function M.enableMeasurement(i2c)
  local msgs = {{M.MemoryMap.POWER_CTL, M.MEASURE}}
  i2c:transfer(M.DEVICE, msgs)
end

function M.readAcceleration(i2c)
  local msgs = {{M.MemoryMap.DATAX0}, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local data = msgs[2]
  local x = M.readShort(data[1], data[2]) * M.ConversionFactor.SCALE_MULTIPLIER
  local y = M.readShort(data[3], data[4]) * M.ConversionFactor.SCALE_MULTIPLIER
  local z = M.readShort(data[5], data[6]) * M.ConversionFactor.SCALE_MULTIPLIER
  return x, y, z
end

function M.readShort(lsb, msb)
  local val = lsb + msb * 256
  if val >= 32768 then val = val - 65536 end
  return val
end

function M.readUShort(lsb, msb)
  return lsb + msb * 256
end

function M.setBandwidthRate(i2c, bandwidthRateFlag)
  local msgs = {{M.MemoryMap.BW_RATE, bandwidthRateFlag}}
  i2c:transfer(M.DEVICE, msgs)
end

function M.setRange(i2c, rangeFlag)
  local msgs = {{M.MemoryMap.DATA_FORMAT}, {0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local value = msgs[2][1]
  value = bit32.band(value, 0xf0)
  value = bit32.bor(value, rangeFlag or M.Range['2_G'])
  value = bit32.bor(value, 0x08)
  msgs = {{M.MemoryMap.DATA_FORMAT, value}}
  i2c:transfer(M.DEVICE, msgs)
end

return M
