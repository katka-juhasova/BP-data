local bit32 = require 'bit32'
local varint = require 'parquet.codec.varint'

--function encodeFixedInt(value, bytes) {
--  switch (bytes) {
--    case 1: { local b = Buffer.alloc(1) b.writeUInt8(value) return b }
--    default: throw 'invalid argument'
--  }
--}

local function decodeFixedInt(buffer, offset, len)
  if len == 1 then
    local b = buffer[offset+1]
    return b
  end
  error('invalid argument')
end

local function decodeRunBitpacked(cursor, count, opts)
  assert(count % 8 == 0, 'must be a multiple of 8')
  local values = {}
  for i=1,count do values[#values+1] = 0 end
  for b=0, opts.bitWidth * count -1 do
    local index = cursor.offset + math.floor(b / 8) + 1
    local byte
    if type(cursor.buffer) == 'table' then
      byte = cursor.buffer[index]
    else
      byte = cursor.buffer:sub(index,index):byte()
    end
    if bit32.band(byte, bit32.lshift(1, b % 8)) ~= 0 then
      local idx = math.floor(b/opts.bitWidth)+1
      values[idx] = bit32.bor(values[idx], bit32.lshift(1, b % opts.bitWidth))
    end
  end
  cursor.offset = cursor.offset + opts.bitWidth * (count / 8)
  return values
end

local M = {}

M.encodeValues = function()
  error('not implemented yet')
--  if (!('bitWidth' in opts)) {
--    throw 'bitWidth is required'
--  }
--
--  switch (type) {
--
--    case 'BOOLEAN':
--    case 'INT32':
--    case 'INT64':
--      values = values.map((x) => parseInt(x, 10))
--      break
--
--    default:
--      throw 'unsupported type: ' + type
--  }
--
--  local buf = Buffer.alloc(0)
--  for (local i = 0 i < values.length ++i) {
--    buf = Buffer.concat([buf, Buffer.from(varint.encode(1 << 1)), encodeFixedInt(values[i], Math.ceil(opts.bitWidth / 8))])
--  }
--
--  if (opts.disableEnvelope) {
--    return buf
--  }
--
--  local envelope = Buffer.alloc(buf.length + 4)
--  envelope.writeUInt32LE(buf.length)
--  buf.copy(envelope, 4)
--
--  return envelope
end

M.decodeValues = function(_, cursor, count, opts)
  assert(opts.bitWidth, 'bitWidth is required')

  if not opts.disableEnvelope then
    cursor.offset = cursor.offset + 4
  end

  local values = {}
  while #values < count do
    local header = varint.decode(cursor.buffer, cursor.offset)
    cursor.offset = cursor.offset + varint.encodingLength(header)

    if bit32.band(header, 1) ~= 0 then -- bit packed run
      local valueCount = bit32.arshift(header, 1) * 8
      local values2 = decodeRunBitpacked(cursor, valueCount, opts)
      for _,value in pairs(values2) do values[#values+1] = value end
    else -- rle run
      local valueCount = bit32.arshift(header, 1)
      local valueSize = math.ceil(opts.bitWidth / 8)
      local value = decodeFixedInt(cursor.buffer, cursor.offset, valueSize)
      for i=1,valueCount do
        values[#values+1] = value
      end
      cursor.offset = cursor.offset + valueSize
    end
  end

  return values
end

return M
