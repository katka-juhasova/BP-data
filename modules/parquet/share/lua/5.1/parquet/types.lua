local M = {}

local function toPrimitive_BOOLEAN(value)
  error('not implemented yet', value)
  return not not value
end

local function fromPrimitive_BOOLEAN(value)
  error('not implemented yet', value)
  return not not value
end

local function toPrimitive_FLOAT(value)
  error('not implemented yet', value)
--  const v = parseFloat(value);
--  if (isNaN(v)) {
--    throw 'invalid value for FLOAT=' + value;
--  }
--
--  return v;
end

local function toPrimitive_DOUBLE(value)
  if value == nil then return nil end
--  const v = parseFloat(value);
  local v = value
  if type(v) == 'string' then v = tonumber(value, 10) end
  if type(v) ~= 'number' then
    error('invalid value for DOUBLE=' .. tostring(value))
  end

  return v
end

local function toPrimitive_INT8(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < -0x80 || v > 0x7f || isNaN(v)) {
--    throw 'invalid value for INT8=' + value;
--  }
--
--  return v;
end

local function toPrimitive_UINT8(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < 0 || v > 0xff || isNaN(v)) {
--    throw 'invalid value for UINT8=' + value;
--  }
--
--  return v;
end

local function toPrimitive_INT16(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < -0x8000 || v > 0x7fff || isNaN(v)) {
--    throw 'invalid value for INT16=' + value;
--  }
--
--  return v;
end

local function toPrimitive_UINT16(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < 0 || v > 0xffff || isNaN(v)) {
--    throw 'invalid value for UINT16=' + value;
--  }
--
--  return v;
end

local function toPrimitive_INT32(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < -0x80000000 || v > 0x7fffffff || isNaN(v)) {
--    throw 'invalid value for INT32=' + value;
--  }
--
--  return v;
end

local function toPrimitive_UINT32(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < 0 || v > 0xffffffffffff || isNaN(v)) {
--    throw 'invalid value for UINT32=' + value;
--  }
--
--  return v;
end

local function toPrimitive_INT64(value)
  if value == nil then return nil end
--  const v = parseInt(value, 10);
  local v = value
  if type(v) == 'string' then v = tonumber(value, 10) end
--  if (isNaN(v)) {
  if type(v) ~= 'number' then
    error('invalid value for INT64=' .. tostring(value))
  end

  return v
end

local function toPrimitive_UINT64(value)
  error('not implemented yet', value)
  if value == nil then return nil end
--  const v = parseInt(value, 10);
  local v = value
  if type(v) == 'string' then v = tonumber(value, 10) end
--  if (v < 0 || isNaN(v)) {
  if v < 0 or type(v) ~= 'number' then
    error('invalid value for UINT64=' .. tostring(value))
  end

  return v
end

local function toPrimitive_INT96(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (isNaN(v)) {
--    throw 'invalid value for INT96=' + value;
--  }
--
--  return v;
end

local function toPrimitive_BYTE_ARRAY(value)
  error('not implemented yet', value)
--  return Buffer.from(value);
end

local function toPrimitive_UTF8(value)
  return tostring(value)
end

local function fromPrimitive_UTF8(value)
  return tostring(value)
end

local function toPrimitive_JSON(value)
  error('not implemented yet', value)
--  return Buffer.from(JSON.stringify(value));
end

local function fromPrimitive_JSON(value)
  error('not implemented yet', value)
--  return JSON.parse(value);
end

local function toPrimitive_BSON(value)
  error('not implemented yet', value)
--  var encoder = new BSON();
--  return Buffer.from(encoder.serialize(value));
end

local function fromPrimitive_BSON(value)
  error('not implemented yet', value)
--  var decoder = new BSON();
--  return decoder.deserialize(value);
end

local function toPrimitive_TIME_MILLIS(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < 0 || v > 0xffffffffffffffff || isNaN(v)) {
--    throw 'invalid value for TIME_MILLIS=' + value;
--  }
--
--  return v;
end

local function toPrimitive_TIME_MICROS(value)
  error('not implemented yet', value)
--  const v = parseInt(value, 10);
--  if (v < 0 || isNaN(v)) {
--    throw 'invalid value for TIME_MICROS=' + value;
--  }
--
--  return v;
end

local function toPrimitive_TIMESTAMP_MILLIS(value)
  error('not implemented yet', value)
  -- convert from date
--  if (value instanceof Date) {
--    return value.getTime();
--  }
--
  -- convert from integer
--  {
--    const v = parseInt(value, 10);
--    if (v < 0 || isNaN(v)) {
--      throw 'invalid value for TIMESTAMP_MILLIS=' + value;
--    }
--
--    return v;
--  }
end

local function fromPrimitive_TIMESTAMP_MILLIS(value)
  error('not implemented yet', value)
--  return new Date(value);
end

local function toPrimitive_TIMESTAMP_MICROS(value)
  error('not implemented yet', value)
  -- convert from date
--  if (value instanceof Date) {
--    return value.getTime() * 1000;
--  }
--
--  -- convert from integer
--  {
--    const v = parseInt(value, 10);
--    if (v < 0 || isNaN(v)) {
--      throw 'invalid value for TIMESTAMP_MICROS=' + value;
--    }
--
--    return v;
--  }
end

local function fromPrimitive_TIMESTAMP_MICROS(value)
  error('not implemented yet', value)
--  return new Date(value / 1000);
end

--[[
  Convert a value from it's native representation to the internal/underlying
  primitive type
--]]
function M.toPrimitive(type, value)
  if M.PARQUET_LOGICAL_TYPES[type] == nil then
    error('invalid type=' .. type)
  end

  return M.PARQUET_LOGICAL_TYPES[type].toPrimitive(value)
end

--[[
  Convert a value from it's internal/underlying primitive representation to
  the native representation
--]]
function M.fromPrimitive(type, value)
  if M.PARQUET_LOGICAL_TYPES[type] == nil then
    error('invalid type=' .. type)
  end
  if M.PARQUET_LOGICAL_TYPES[type].fromPrimitive then
    return M.PARQUET_LOGICAL_TYPES[type].fromPrimitive(value)
  else
    return value
  end
end

M.PARQUET_LOGICAL_TYPES = {
  ['BOOLEAN']={
    primitiveType='BOOLEAN',
    toPrimitive=toPrimitive_BOOLEAN,
    fromPrimitive=fromPrimitive_BOOLEAN
  },
  ['INT32']={
    primitiveType='INT32',
    toPrimitive=toPrimitive_INT32
  },
  ['INT64']={
    primitiveType='INT64',
    toPrimitive=toPrimitive_INT64
  },
  ['INT96']={
    primitiveType='INT96',
    toPrimitive=toPrimitive_INT96
  },
  ['FLOAT']={
    primitiveType='FLOAT',
    toPrimitive=toPrimitive_FLOAT
  },
  ['DOUBLE']={
    primitiveType='DOUBLE',
    toPrimitive=toPrimitive_DOUBLE
  },
  ['BYTE_ARRAY']={
    primitiveType='BYTE_ARRAY',
    toPrimitive=toPrimitive_BYTE_ARRAY
  },
  ['UTF8']={
    primitiveType='BYTE_ARRAY',
    originalType='UTF8',
    toPrimitive=toPrimitive_UTF8,
    fromPrimitive=fromPrimitive_UTF8
  },
  ['TIME_MILLIS']={
    primitiveType='INT32',
    originalType='TIME_MILLIS',
    toPrimitive=toPrimitive_TIME_MILLIS
  },
  ['TIME_MICROS']={
    primitiveType='INT64',
    originalType='TIME_MICROS',
    toPrimitive=toPrimitive_TIME_MICROS
  },
  ['TIMESTAMP_MILLIS']={
    primitiveType='INT64',
    originalType='TIMESTAMP_MILLIS',
    toPrimitive=toPrimitive_TIMESTAMP_MILLIS,
    fromPrimitive=fromPrimitive_TIMESTAMP_MILLIS
  },
  ['TIMESTAMP_MICROS']={
    primitiveType='INT64',
    originalType='TIMESTAMP_MICROS',
    toPrimitive=toPrimitive_TIMESTAMP_MICROS,
    fromPrimitive=fromPrimitive_TIMESTAMP_MICROS
  },
  ['UINT_8']={
    primitiveType='INT32',
    originalType='UINT_8',
    toPrimitive=toPrimitive_UINT8
  },
  ['UINT_16']={
    primitiveType='INT32',
    originalType='UINT_16',
    toPrimitive=toPrimitive_UINT16
  },
  ['UINT_32']={
    primitiveType='INT32',
    originalType='UINT_32',
    toPrimitive=toPrimitive_UINT32
  },
  ['UINT_64']={
    primitiveType='INT64',
    originalType='UINT_64',
    toPrimitive=toPrimitive_UINT64
  },
  ['INT_8']={
    primitiveType='INT32',
    originalType='INT_8',
    toPrimitive=toPrimitive_INT8
  },
  ['INT_16']={
    primitiveType='INT32',
    originalType='INT_16',
    toPrimitive=toPrimitive_INT16
  },
  ['INT_32']={
    primitiveType='INT32',
    originalType='INT_32',
    toPrimitive=toPrimitive_INT32
  },
  ['INT_64']={
    primitiveType='INT64',
    originalType='INT_64',
    toPrimitive=toPrimitive_INT64
  },
  ['JSON']={
    primitiveType='BYTE_ARRAY',
    originalType='JSON',
    toPrimitive=toPrimitive_JSON,
    fromPrimitive=fromPrimitive_JSON
  },
  ['BSON']={
    primitiveType='BYTE_ARRAY',
    originalType='BSON',
    toPrimitive=toPrimitive_BSON,
    fromPrimitive=fromPrimitive_BSON
  }
}

return M
