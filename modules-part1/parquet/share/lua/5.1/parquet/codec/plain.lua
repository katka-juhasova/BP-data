local bit32 = require 'bit32'
local vstruct = require 'vstruct'

local encodeValues_BOOLEAN = function(values)
  error('not implemented yet', values)
end

local decodeValues_BOOLEAN = function(cursor, count)
  local values = {}
  for i=0,count-1 do
    local b = string.byte(cursor.buffer, cursor.offset+1 + math.floor(i / 8))
    values[#values+1] = (bit32.band(b, bit32.lshift(1, i % 8)) > 0) -- (b & (1 << (i % 8))) > 0)
  end
  cursor.offset = cursor.offset + math.ceil(count / 8)
  return values
end

local encodeValues_INT32 = function(values)
  local buf = ''
  for i=1,#values do
    buf = buf .. vstruct.write('< i4', {values[i]})
  end
  return buf
end

local decodeValues_INT32 = function(cursor, count)
  local values = {}
  for i=1,count do
    vstruct.read('< i4', string.sub(cursor.buffer, cursor.offset+1, cursor.offset+4), values)
    cursor.offset = cursor.offset + 4
  end
  return values
end

local encodeValues_INT64 = function(values)
  error('not implemented yet', values)
end

local decodeValues_INT64 = function(cursor, count)
  local values = {}

  for i=1,count do
    vstruct.read('< i8', string.sub(cursor.buffer, cursor.offset+1, cursor.offset+8), values)
    cursor.offset = cursor.offset + 8
  end

  return values
end

local encodeValues_INT96 = function(values)
  error('not implemented yet', values)
end

local decodeValues_INT96 = function(cursor, count)
  error('not implemented yet', cursor, count)
end

local encodeValues_FLOAT = function(values)
  error('not implemented yet', values)
end

local decodeValues_FLOAT = function(cursor, count)
  local values = {}
  for i=1,count do
    vstruct.read('< f4', string.sub(cursor.buffer, cursor.offset+1, cursor.offset+4), values)
    cursor.offset = cursor.offset + 4
  end
  return values
end

local encodeValues_DOUBLE = function(values)
  error('not implemented yet', values)
end

local decodeValues_DOUBLE = function(cursor, count)
  local values = {}
  for i=1,count do
    vstruct.read('< f8', string.sub(cursor.buffer, cursor.offset+1, cursor.offset+8), values)
    cursor.offset = cursor.offset + 8
  end
  return values
end

local encodeValues_BYTE_ARRAY = function(values)
  error('not implemented yet', values)
end

local decodeValues_BYTE_ARRAY = function(cursor, count)
  error('not implemented yet', cursor, count)
end

local M = {}

M.encodeValues = function(type, values)
  if type == 'BOOLEAN' then
    return encodeValues_BOOLEAN(values)

  elseif type == 'INT32' then
    return encodeValues_INT32(values)

  elseif type == 'INT64' then
    return encodeValues_INT64(values)

  elseif type == 'INT96' then
    return encodeValues_INT96(values)

  elseif type == 'FLOAT' then
    return encodeValues_FLOAT(values)

  elseif type == 'DOUBLE' then
    return encodeValues_DOUBLE(values)

  elseif type == 'BYTE_ARRAY' then
    return encodeValues_BYTE_ARRAY(values)

  else
    error('unsupported type: ' .. type)

  end
end

M.decodeValues = function(type, cursor, count)
  if type == 'BOOLEAN' then
    return decodeValues_BOOLEAN(cursor, count)
    
  elseif type == 'INT32' then
    return decodeValues_INT32(cursor, count)
    
  elseif type == 'INT64' then
    return decodeValues_INT64(cursor, count)
    
  elseif type == 'INT96' then
    return decodeValues_INT96(cursor, count)
    
  elseif type == 'FLOAT' then
    return decodeValues_FLOAT(cursor, count)
    
  elseif type == 'DOUBLE' then
    return decodeValues_DOUBLE(cursor, count)
    
  elseif type == 'BYTE_ARRAY' then
    return decodeValues_BYTE_ARRAY(cursor, count)
    
  else
    error('unsupported type: ' .. type)
  
  end
end

return M
