local bit32 = require 'bit32'

local M = {}

local MSB = 0x80
local REST = 0x7F
local MSBALL = bit32.bnot(REST)
local INT = math.pow(2, 31)

function M.decode(buf, offset)
  offset = offset or 0
  local counter = offset
  local res, shift = 0, 0
  repeat
    assert(counter < #buf, 'Could not decode varint; range error')
    local b
    if type(buf) == 'table' then
      b = buf[counter+1]
    else
      b = buf:sub(counter+1,counter+1):byte()
    end
    counter = counter + 1
    if shift < 28 then
      res = res + bit32.lshift(bit32.band(b, REST), shift)
    else
      res = res + bit32.band(b, REST) * math.pow(2, shift)
    end
    shift = shift + 7
  until b < MSB

  local readBytes = counter - offset
  return res, readBytes
end

function M.encode(num, out, offset)
  if type(num) == 'table' then return {0} end
  out = out or {}
  offset = offset or 0
  local oldOffset = offset

  while num >= INT do
    out[offset+1] = bit32.bor(bit32.band(num, 0xFF), MSB)
    offset = offset + 1
    num = num / 128
  end
  while bit32.band(num, MSBALL) ~= 0 do
    out[offset+1] = bit32.bor(bit32.band(num, 0xFF), MSB)
    offset = offset + 1
    num = bit32.rshift(num, 7)
  end
  out[offset+1] = bit32.bor(num, 0)
  local encodeBytes = offset - oldOffset + 1
  return out, encodeBytes
end

local N1 = math.pow(2,  7)
local N2 = math.pow(2, 14)
local N3 = math.pow(2, 21)
local N4 = math.pow(2, 28)
local N5 = math.pow(2, 35)
local N6 = math.pow(2, 42)
local N7 = math.pow(2, 49)
local N8 = math.pow(2, 56)
local N9 = math.pow(2, 63)

function M.encodingLength(value)
  if value < N1 then return 1 end
  if value < N2 then return 2 end
  if value < N3 then return 3 end
  if value < N4 then return 4 end
  if value < N5 then return 5 end
  if value < N6 then return 6 end
  if value < N7 then return 7 end
  if value < N8 then return 8 end
  if value < N9 then return 9 end
  return 10
end

return M
