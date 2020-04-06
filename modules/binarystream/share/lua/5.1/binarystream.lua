local ffi = require "ffi"
local band, bor, bnot, shl, shr = bit.band, bit.bor, bit.bnot, bit.lshift, bit.rshift
local _native_endian

-----------------------------------------------------------------------------

local BinaryStream = {}

function BinaryStream:init(data, size, options)
	local options = options or {}

	self._endian = BinaryStream._parse_endian(options.endianess)
	self._endian_conv = self._endian == _native_endian
		and function() end
		or BinaryStream._swap_bytes

	self._native = ffi.new[[
		union {
			  int8_t s8;
			 uint8_t u8;
			 int16_t s16;
			uint16_t u16;
			 int32_t s32;
			uint32_t u32;
			   float f32;
			 int64_t s64;
			uint64_t u64;
			  double f64;
		}
	]]
	self._native_buf = ffi.cast("uint8_t *", self._native)
	self._length = 0

	if not data then
		self:_allocate(10)
	else
		local t = type(data)
		if t == 'string' then
			self:_allocateMin(math.max(size or 0, #data))
			self._length = #data
		elseif t == 'cdata' then
			local size = math.max(size or 0, ffi.sizeof(data) or 0)
			assert(size > 0, "Invalid or unknown size of object")
			self:_allocateMin(size)
			self._size, self._length = size, size
		else
			error("Invalid data type <" .. t .. ">")
		end

		ffi.copy(self._data, data, self._length)
	end

	self._position = 0

	return self
end

-----------------------------------------------------------------------------

function BinaryStream:readRaw(count)
	self:_assert_readable(count)

	local pos = self._position
	self._position = pos + count
	return ffi.string(self._data + pos, count)
end

function BinaryStream:skip(count)
	self:_assert_readable(count)
	self._position = self._position + count

	return self
end

function BinaryStream:writeRaw(value)
	local count = #value

	self:_grow(self._length + count)
	ffi.copy(self._data + self._length, value, count)
	self._length = self._length + count

	return self
end

-----------------------------------------------------------------------------

function BinaryStream:readU8()
	return self:_read(1).u8
end

function BinaryStream:readS8()
	return self:_read(1).s8
end

function BinaryStream:readU16()
	return self:_read(2).u16
end

function BinaryStream:readS16()
	return self:_read(2).s16
end

function BinaryStream:readU32()
	return self:_read(4).u32
end

function BinaryStream:readS32()
	return self:_read(4).s32
end

function BinaryStream:readF32()
	return self:_read(4).f32
end

function BinaryStream:readU64()
	return self:_read(8).u64
end

function BinaryStream:readS64()
	return self:_read(8).s64
end

function BinaryStream:readF64()
	return self:_read(8).f64
end

-----------------------------------------------------------------------------

function BinaryStream:writeU8(value)
	self._native.u8 = value
	return self:_write(1)
end

function BinaryStream:writeS8(value)
	self._native.s8 = value
	return self:_write(1)
end

function BinaryStream:writeU16(value)
	self._native.u16 = value
	return self:_write(2)
end

function BinaryStream:writeS16(value)
	self._native.s16 = value
	return self:_write(2)
end

function BinaryStream:writeU32(value)
	self._native.u32 = value
	return self:_write(4)
end

function BinaryStream:writeS32(value)
	self._native.s32 = value
	return self:_write(4)
end

function BinaryStream:writeF32(value)
	self._native.f32 = value
	return self:_write(4)
end

function BinaryStream:writeU64(value)
	self._native.u64 = value
	return self:_write(8)
end

function BinaryStream:writeS64(value)
	self._native.s64 = value
	return self:_write(8)
end

function BinaryStream:writeF64(value)
	self._native.f64 = value
	return self:_write(8)
end

-----------------------------------------------------------------------------

function BinaryStream:readBool()
	return self:readU8() == 0xFF
end

function BinaryStream:writeBool(value)
	return self:writeU8(value and 0xFF or 0x00)
end

-----------------------------------------------------------------------------

function BinaryStream:readVarS32()
	local result = self:readVarU32()
	local neg = band(result, 0x00000001) == 1
	result = shr(result, 1)

	if neg then result = -result end

	return result
end

function BinaryStream:writeVarS32(value)
	assert(value > -(2 ^ 31) and value < 2 ^ 31, "Exceeded S32 value range")

	if value < 0 then
		value = bor(shl(-value, 1), 0x00000001)
	else
		value = shl(value, 1)
	end

	return self:writeVarU32(value)
end

-----------------------------------------------------------------------------

function BinaryStream:readVarU32()
	local result = self:readU8()
	if band(result, 0x00000080) == 0 then return result end

	result = band(result, 0x0000007f) + self:readU8() * 2 ^ 7
	if band(result, 0x00004000) == 0 then return result end

	result = band(result, 0x00003fff) + self:readU8() * 2 ^ 14
	if band(result, 0x00200000) == 0 then return result end

	result = band(result, 0x001fffff) + self:readU8() * 2 ^ 21
	if band(result, 0x10000000) == 0 then return result end

	return band(result, 0x0fffffff) + self:readU8() * 2 ^ 28
end

function BinaryStream:writeVarU32(value)
	assert(value >= 0 and value < 2 ^ 32, "Exceeded U32 value range")
	for i = 7, 28, 7 do
		local mask, shift = 2 ^ i - 1, i - 7
		if value < 2 ^ i then
			return self:writeU8(shr(band(value, mask), shift))
		else
			self:writeU8(shr(band(value, mask), shift) + 0x80)
		end
	end
	return self:writeU8(shr(band(value, 0xf0000000), 28))
end

-----------------------------------------------------------------------------

function BinaryStream:readString()
	local len = self:readVarU32()
	return self:readRaw(len)
end

function BinaryStream:writeString(value)
	return self:writeVarU32(#value):writeRaw(value)
end

-----------------------------------------------------------------------------

function BinaryStream:string()
	return ffi.string(self._data, self._length)
end

function BinaryStream:length()
	return self._length
end

function BinaryStream:clean()
	self._length = 0
	return self
end

function BinaryStream:position()
	return self._position
end

function BinaryStream:rewind()
	self._position = 0
	return self
end

-----------------------------------------------------------------------------

local logof2 = math.log(2)
function BinaryStream._log2(v)
	return math.log(v) / logof2
end

_native_endian = ffi.abi("le") and "le" or "be"
function BinaryStream._parse_endian(endian)
	if not endian or endian == "=" or endian == "native" then
		return _native_endian
	elseif endian == "<" or endian == "le" then
		return "le"
	elseif endian == ">" or endian == "be" then
		return "be"
	end

	error("Invalid endianess \"" .. endian .. "\"")
end

function BinaryStream._swap_bytes(pointer, count)
	local i, j
	i, j = 0, count - 1

	while i < j do
		pointer[i], pointer[j] = pointer[j], pointer[i]

		i = i + 1
		j = j - 1
	end
end

function BinaryStream:_assert_readable(count)
	assert(self._position + count <= self._length, "Out of data")
end

function BinaryStream:_read(count)
	self:_assert_readable(count)

	ffi.copy(self._native, self._data + self._position, count)
	self._endian_conv(self._native_buf, count)

	self._position = self._position + count
	return self._native
end

function BinaryStream:_write(count)
	self:_grow(self._length + count)

	self._endian_conv(self._native_buf, count)
	ffi.copy(self._data + self._length, self._native, count)

	self._length = self._length + count
	return self
end

function BinaryStream:_allocateMin(size)
	self:_allocate(math.pow(2, math.ceil(BinaryStream._log2(size))))
end

function BinaryStream:_allocate(size)
	local data
	if size > 0 then
		data = ffi.new("uint8_t[?]", size)
		if self._data then
			ffi.copy(data, self._data, self._length)
		end
	end

	self._data, self._size = data, size
	self._length = math.min(size, self._length)
end

function BinaryStream:_grow(min)
	local min = min or 0
	if min >= self._size then
		local new_size = self._size * 2
		self:_allocate(new_size)
	end
end

-----------------------------------------------------------------------------

return setmetatable({}, {
	__call = function(self, ...)
		return setmetatable({}, { __index = BinaryStream }):init(...)
	end
})