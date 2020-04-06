local I2C = require 'periphery'.I2C
local socket = require 'socket'

local M = {
  Command = {
    GetFeatureSet     = {0x20, 0x2f},
    InitAirQuality    = {0x20, 0x03},
    MeasureAirQuality = {0x20, 0x08},
    MeasureRawSignals = {0x20, 0x50},
    MeasureTest       = {0x20, 0x32}
  },
  DEVICE = 0x58
}

function M.initAirQuality(i2c, device)
  i2c:transfer(device or M.DEVICE, {M.Command.InitAirQuality})
  socket.sleep(.010)
end

function M.measureAirQuality(i2c, device)
  i2c:transfer(device or M.DEVICE, {M.Command.MeasureAirQuality})
  socket.sleep(.012)
  local msg = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}
  i2c:transfer(device or M.DEVICE, {msg})
  local co2PPM = msg[1]*256 + msg[2]
  local vocPPB = msg[4]*256 + msg[5]
  return co2PPM, vocPPB
end

function M.measureRawSignals(i2c, device)
  i2c:transfer(device or M.DEVICE, {M.Command.MeasureRawSignals})
  socket.sleep(.025)
  local msg = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}
  i2c:transfer(device or M.DEVICE, {msg})
  local sout_H2 = msg[1]*256 + msg[2]
  local sout_EthOH = msg[4]*256 + msg[5]
  return sout_H2, sout_EthOH
end

function M.measureTest(i2c, device)
  i2c:transfer(device or M.DEVICE, {M.Command.MeasureTest})
  socket.sleep(.220)
  local msg = {0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}
  i2c:transfer(device or M.DEVICE, {msg})
  local result = msg[1]*256 + msg[2]
  return result == 0xd400
end

function M.readVersion(i2c, device)
  i2c:transfer(device or M.DEVICE, {M.Command.GetFeatureSet})
  socket.sleep(.002)
  local msg = {0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}
  i2c:transfer(device or M.DEVICE, {msg})
  local lsb = msg[2]
  return lsb
end

return M
