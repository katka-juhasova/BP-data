local vstruct = require("vstruct")

local DecodeStream = {}
DecodeStream.__index = DecodeStream

function DecodeStream.new(buffer)
  local d = {}
  setmetatable(d, DecodeStream)
  d.buffer = vstruct.cursor(buffer)
  d.length = #buffer
  return d
end

DecodeStream.types = {
  UInt8 = "u1",
  UInt16LE = "<u2", UInt16BE = ">u2",
  UInt24LE = "<u3", UInt24BE = ">u3",
  UInt32LE = "<u4", UInt32BE = ">u4",
  Int8 = "i1",
  Int16LE = "<i2", Int16BE = ">i2",
  Int24LE = "<i3", Int24BE = ">i3",
  Int32LE = "<i4", Int32BE = ">i4",
  FloatLE = "<f4", FloatBE = ">f4",
  DoubleLE = "<f8", DoubleBE = ">f8"
}

local function getReaderFunc(fmt)
  return function(self)
    return vstruct.readvals(fmt, self.buffer)
  end
end

for k,fmt in pairs(DecodeStream.types) do
  DecodeStream["read"..k] = getReaderFunc(fmt)
end

function DecodeStream:readString(length)
  if length then
    return vstruct.readvals("s"..length, self.buffer)
  else
    return vstruct.readvals("z", self.buffer)
  end
end

function DecodeStream:readBuffer(length)
  return vstruct.readvals("s"..length, self.buffer)
end

return DecodeStream
