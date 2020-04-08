local DecodeStream = require("restructure.DecodeStream")

local NumberT = {}
NumberT.__index = NumberT

function NumberT.new(type, endian)
  endian = endian or "BE"
  local nt = {}
  setmetatable(nt, NumberT)

  nt.type = type
  nt.endian = endian or "BE"

  nt.fn = type
  if string.sub(type, #type) ~= '8' then nt.fn = nt.fn..endian end

  return nt
end

function NumberT:size()
  local fmt = DecodeStream.types[self.type] or DecodeStream.types[self.type..self.endian]
  return  tonumber(string.sub(fmt, #fmt))
end

function NumberT:decode(stream)
  return stream['read'..self.fn](stream)
end

function NumberT:encode(stream, val)
  return stream['write'..self.fn](stream,val)
end

local exports = {}

exports.Number = NumberT
exports.uint8 = NumberT.new('UInt8')
exports.uint16 = NumberT.new('UInt16', 'BE')
exports.uint16be = exports.uint16
exports.uint16le = NumberT.new('UInt16', 'LE')
exports.uint24 = NumberT.new('UInt24', 'BE')
exports.uint24be = exports.uint24
exports.uint24le = NumberT.new('UInt24', 'LE')
exports.uint32 = NumberT.new('UInt32', 'BE')
exports.uint32be = exports.uint32
exports.uint32le = NumberT.new('UInt32', 'LE')
exports.int8 = NumberT.new('Int8')
exports.int16 = NumberT.new('Int16', 'BE')
exports.int16be = exports.int16
exports.int16le = NumberT.new('Int16', 'LE')
exports.int24 = NumberT.new('Int24', 'BE')
exports.int24be = exports.int24
exports.int24le = NumberT.new('Int24', 'LE')
exports.int32 = NumberT.new('Int32', 'BE')
exports.int32be = exports.int32
exports.int32le = NumberT.new('Int32', 'LE')
exports.float = NumberT.new('Float', 'BE')
exports.floatbe = exports.float
exports.floatle = NumberT.new('Float', 'LE')
exports.double = NumberT.new('Double', 'BE')
exports.doublebe = exports.double
exports.doublele = NumberT.new('Double', 'LE')

local Fixed = {}
Fixed.__index = Fixed
setmetatable(Fixed, NumberT)

function Fixed.new(size, endian, fracBits)
  local ft = NumberT.new("Int"..size, endian)
  setmetatable(ft, Fixed)
  ft.at_point = bit32.lshift(1, fracBits or bit32.rshift(size, 1))
  return ft
end

function Fixed:decode(stream)
  return NumberT.decode(self, stream)/ self.at_point
end

function Fixed:encode(stream,val)
  NumberT.encode(self,stream, val * self.at_point)
end

exports.Fixed = Fixed
exports.fixed16 = Fixed.new(16, 'BE')
exports.fixed16be = exports.fixed16
exports.fixed16le = Fixed.new(16, 'LE')
exports.fixed32 =Fixed.new(32, 'BE')
exports.fixed32be = exports.fixed32
exports.fixed32le = Fixed.new(32, 'LE')

return exports