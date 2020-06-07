local bit32 = require 'bit32'
local I2C = require 'periphery'.I2C

local M = {
  AccuracyMode = {
    ULTRA_LOW  = 0, --  x1 sample
    LOW        = 1, --  x2 samples
    STANDARD   = 2, --  x4 samples
    HIGH       = 3, --  x8 samples
    ULTRA_HIGH = 4  -- x16 samples
  },
  
  DEVICE = 0x76,
  
  -- memory map
  ID_REG                = 0xD0,
  RESET                 = 0xE0,
  CTRL_HUM              = 0xF2,
  STATUS                = 0xF3,
  CTRL_MEAS             = 0xF4,
  CONFIG                = 0xF5, -- TODO: support IIR filter settings
  PRESS_OUT_MSB_LSB_XLSB= 0xF7, -- 3-byte
  TEMP_OUT_MSB_LSB_XLSB = 0xFA, -- 3-byte
  HUM_OUT_MSB_LSB       = 0xFD, -- 3-byte
  
  -- memory map: compensation register's blocks
  COEF_PART1_START = 0x88,
  COEF_PART2_START = 0xA1,
  COEF_PART3_START = 0xE1
}

function M.getOversamplingRation(accuracyMode)
  return accuracyMode + 1
end

-- reads register 0xF3 for "busy" flag, according to sensor specification
function M.isBusy(i2c)
  -- Check flag to know status of calculation, according
  -- to specification about SCO (Start of conversion) flag
  local msgs = {{M.STATUS}, {0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local busy = bit32.band(msgs[2][1], 0x8)
  return busy ~= 0, nil
end

function M.readChar(lsb)
  local val = lsb
  if val >= 128 then val = val - 256 end
  return val
end

-- read compensation coefficients, unique for each sensor
function M.readCoefficients(i2c)
  local msgs = {
    {M.COEF_PART1_START},
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}
  }
  i2c:transfer(M.DEVICE, msgs)
  local coef1 = msgs[2]

  msgs = {{M.COEF_PART2_START}, {0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local coef2 = msgs[2]

  msgs = {{M.COEF_PART3_START}, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local coef3 = msgs[2]

  local dig_H4 = M.readChar(coef3[4])
  dig_H4 = bit32.rshift(bit32.lshift(dig_H4,24), 20)
  dig_H4 = bit32.bor(dig_H4, bit32.band(M.readChar(coef3[5]), 0x0f))

  local dig_H5 = M.readChar(coef3[6])
  dig_H5 = bit32.rshift(bit32.lshift(dig_H5,24), 20)
  dig_H5 = bit32.bor(dig_H5, bit32.band(bit32.rshift(M.readChar(coef3[5]),4), 0x0f))

  return {
    dig_T1 = M.readUShort(coef1[ 1], coef1[ 2]),
    dig_T2 = M.readShort (coef1[ 3], coef1[ 4]),
    dig_T3 = M.readShort (coef1[ 5], coef1[ 6]),
    
    dig_P1 = M.readUShort(coef1[ 7], coef1[ 8]),
    dig_P2 = M.readShort (coef1[ 9], coef1[10]),
    dig_P3 = M.readShort (coef1[11], coef1[12]),
    dig_P4 = M.readShort (coef1[13], coef1[14]),
    dig_P5 = M.readShort (coef1[15], coef1[16]),
    dig_P6 = M.readShort (coef1[17], coef1[18]),
    dig_P7 = M.readShort (coef1[19], coef1[20]),
    dig_P8 = M.readShort (coef1[21], coef1[22]),
    dig_P9 = M.readShort (coef1[23], coef1[24]),
    
    dig_H1 = coef2[1],
    dig_H2 = M.readShort(coef3[1], coef3[2]), 
    dig_H3 = coef3[3],
    dig_H4 = dig_H4,
    dig_H5 = dig_H5,
    dig_H6 = M.readChar(coef3[7])
  }
end

-- reads and calculates humidity in %RH
function M.readHumidityRH(i2c,accuracyMode, coeff)
  local ut = M.readUncompensatedTemperature(i2c, accuracyMode)
  local uh = M.readUncompensatedHumidity(i2c, accuracyMode)
  local var01 = bit32.rshift(
    (bit32.rshift(ut,3) - bit32.lshift(coeff.dig_T1,1)) * coeff.dig_T2,
    11
  )
  local var02 = bit32.rshift(
    bit32.rshift((bit32.rshift(ut,4) - coeff.dig_T1) * (bit32.rshift(ut,4) - coeff.dig_T1), 12) * coeff.dig_T3,
    14
  )
  local tFine = var01 + var02
  local var_H = tFine - 76800
  var_H = (uh - (coeff.dig_H4 * 64 + coeff.dig_H5 / 16384 * var_H))
    * (coeff.dig_H2 / 65536 * (1 + coeff.dig_H6 / 67108864 * var_H * (1 + coeff.dig_H3 / 67108864 * var_H)))
  var_H = var_H * (1 - coeff.dig_H1 * var_H / 524288)
  if var_H > 100 then
    var_H = 100
  elseif var_H < 0 then
    var_H = 0
  end
  return var_H
end

-- reads and calculates atmospheric pressure in Pascals
function M.readPressurePa(i2c, accuracyMode, coeff)
  local ut, up = M.readUncompensatedTemperatureAndPressure(i2c, accuracyMode)
  local var01 = bit32.rshift(
    (bit32.rshift(ut,3) - bit32.lshift(coeff.dig_T1,1)) * coeff.dig_T2,
    11
  )
  local var02 = bit32.rshift(
    bit32.rshift((bit32.rshift(ut,4) - coeff.dig_T1) * (bit32.rshift(ut,4) - coeff.dig_T1), 12) * coeff.dig_T3,
    14
  )
  local tFine = var01 + var02
  local var1 = tFine / 2 - 64000
  local var2 = var1 * var1 * coeff.dig_P6 / 32768
  var2 = var2 + var1 * coeff.dig_P5 * 2
  var2 = var2 / 4 + coeff.dig_P4 * 65536
  var1 = (var1 * var1 * coeff.dig_P3 / 524288 + var1 * coeff.dig_P2) / 524288
  var1 = (1 + var1 / 32768) * coeff.dig_P1
  if var1 == 0 then return 0 end
  local p = 1048576 - up
  p = ((p - var2 / 4096) * 6250) / var1
  var1 = coeff.dig_P9 * p * p / 2147483648
  var2 = p * coeff.dig_P8 / 32768
  p = p + (var1 + var2 + coeff.dig_P7) / 16
  return p / 100
end

function M.readSensorID(i2c)
  local msgs = {{M.ID_REG}, {0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local id = msgs[2][1]
  return id
end

function M.readShort(lsb, msb)
  local val = lsb + msb * 256
  if val >= 32768 then val = val - 65536 end
  return val
end

function M.readUShort(lsb, msb)
  return lsb + msb * 256
end

-- reads and calculates temperature in C
function M.readTemperatureC(i2c, accuracyMode, coeff)
  local ut = M.readUncompensatedTemperature(i2c, accuracyMode)
  local var1 = bit32.rshift(
    (bit32.rshift(ut,3) - bit32.lshift(coeff.dig_T1,1)) * coeff.dig_T2,
    11
  )
  local var2 = bit32.rshift(
    bit32.rshift((bit32.rshift(ut,4) - coeff.dig_T1) * (bit32.rshift(ut,4) - coeff.dig_T1), 12) * coeff.dig_T3,
    14
  )
  local tFine = var1 + var2
  local t = bit32.rshift((tFine*5 + 128), 8) / 100
  return t
end

function M.readUncompensatedHumidity(i2c, accuracyMode)
  local power = 1 -- forced mode
  local osrt = M.getOversamplingRation(accuracyMode)
  local msgs = {{M.CTRL_MEAS, bit32.bor(power, bit32.lshift(osrt,5))}}
  i2c:transfer(M.DEVICE, msgs)
  M.waitForCompletion(i2c)
  local osrh = M.getOversamplingRation(M.AccuracyMode.ULTRA_LOW)
  msgs = {{M.CTRL_HUM, osrh}}
  i2c:transfer(M.DEVICE, msgs)
  M.waitForCompletion(i2c)
  msgs = {{M.HUM_OUT_MSB_LSB}, {0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local uh = bit32.lshift(msgs[2][1],8) + msgs[2][2]
  return uh
end

function M.readUncompensatedPressure(i2c, accuracyMode)
  local power = 1 -- forced mode
  local osrp = M.getOversamplingRation(accuracyMode)
  local msgs = {{M.CTRL_MEAS, bit32.bor(power, bit32.lshift(osrp,2))}}
  i2c:transfer(M.DEVICE, msgs)
  M.waitForCompletion(i2c)
  msgs = {{M.PRESS_OUT_MSB_LSB_XLSB}, {0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local up = bit32.lshift(msgs[2][1],12) + bit32.lshift(msgs[2][2],4) + bit32.rshift(bit32.band(msgs[2][3],0xf0),4)
  return up
end

function M.readUncompensatedTemperature(i2c, accuracyMode)
  local power = 1 -- forced mode
  local osrt = M.getOversamplingRation(accuracyMode)
  local msgs = {{M.CTRL_MEAS, bit32.bor(power, bit32.lshift(osrt,5))}}
  i2c:transfer(M.DEVICE, msgs)
  msgs = {{M.TEMP_OUT_MSB_LSB_XLSB}, {0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local ut = bit32.lshift(msgs[2][1],12) + bit32.lshift(msgs[2][2],4) + bit32.rshift(bit32.band(msgs[2][3],0xf0),4) 
  return ut
end

function M.readUncompensatedTemperatureAndPressure(i2c, accuracyMode)
  local power = 1 -- forced mode
  local osrt = M.getOversamplingRation(M.AccuracyMode.STANDARD)
  local osrp = M.getOversamplingRation(accuracyMode)
  local msgs = {{M.CTRL_MEAS, bit32.bor(bit32.bor(power, bit32.lshift(osrt,5)), bit32.lshift(osrp,2))}}
  i2c:transfer(M.DEVICE, msgs)
  M.waitForCompletion(i2c)
  msgs = {{M.TEMP_OUT_MSB_LSB_XLSB}, {0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local ut = bit32.lshift(msgs[2][1],12) + bit32.lshift(msgs[2][2],4) + bit32.rshift(bit32.band(msgs[2][3],0xf0),4) 
  msgs = {{M.PRESS_OUT_MSB_LSB_XLSB}, {0x00, 0x00, 0x00, flags=I2C.I2C_M_RD}}
  i2c:transfer(M.DEVICE, msgs)
  local up = bit32.lshift(msgs[2][1],12) + bit32.lshift(msgs[2][2],4) + bit32.rshift(bit32.band(msgs[2][3],0xf0),4)
  return ut, up
end

function M.sleep(secs)
  local has_luasocket, socket = pcall(require, 'socket')
  if has_luasocket then
    return socket.sleep(secs)
  end
  -- cannot sleep
end

-- Wait until sensor completes measurements and calculations, otherwise return on timeout
function M.waitForCompletion(i2c)
  for i=1,10 do
    local busy = M.isBusy(i2c)
    if not busy then return false end
    M.sleep(.005)
  end
  return true
end

return M
