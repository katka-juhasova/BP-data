local TCompactProtocol = require 'thrift.protocol.TCompactProtocol'
local TMemoryBuffer = require 'thrift.transport.TMemoryBuffer'
local TFramedTransport = require 'thrift.transport.TFramedTransport'

local function log2(n)
  return math.log(n) / math.log(2)
end

local M = {}

M.arrayClone = function(t)
  local r = {}
  for k,v in pairs(t) do r[k] = v end
  return r
end

M.arrayPush = function(t, value)
  if M.isArray(value) then
    for _, v in pairs(value) do t[#t+1] = v end
  else
    t[#t+1] = value
  end
  return t
end

M.decodeThrift = function(obj, buf, offset)
  offset = offset or 0
  local transport = TFramedTransport:new(buf)
  transport.readPos = offset + 1 -- readPos is 1-based
  local protocol = TCompactProtocol:new(transport)
  obj:read(protocol)
  return transport.readPos - offset - 1
end

M.fclose = function(file)
  file:close()
end

M.fopen = function(filePath)
  local file = assert(io.open(filePath, 'r'))
  return file
end

M.fread = function(file, position, length)
  file:seek('set', position)
  return file:read(length)
end

M.fsize = function(file)
  return file:seek('end')
end

-- Get the number of bits required to store a given value
M.getBitWidth = function(val)
  if val == 0 then
    return 0
  else
    return math.ceil(log2(val + 1))
  end
end

M.getThriftEnum = function(klass, value)
  for k,v in pairs(klass) do
    if v == value then return k end
  end
end

M.isArray = function(t)
  if type(t) ~= 'table' then return false end
  local i = 0
  for _ in pairs(t) do
     i = i + 1
     if t[i] == nil then return false end
  end
  return true
end

M.isInstanceOf = function(obj, class)
  return type(obj) == 'table' and obj.isInstanceOf and obj:isInstanceOf(class)
end

M.iterator = function(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

M.keyCount = function(t)
  local c = 0
  for _ in pairs(t) do c = c + 1 end
  return c
end

-- serialize a thrift object into a buffer
M.serializeThrift = function(obj)
  local memoryBuffer = TMemoryBuffer:new()
  local protocol = TCompactProtocol:new(memoryBuffer)
  obj:write(protocol)
  return memoryBuffer:getBuffer()
end

-- JavaScript splice, but using Lua 1-based indexes
M.splice = function(t, start, deleteCount)
  local removed = {}
  local endIndexInclusive
  if deleteCount == nil then
    endIndexInclusive = #t
  else
    endIndexInclusive = start + deleteCount - 1
  end
  for i=endIndexInclusive, start, -1 do
    table.insert(removed, 1, t[i])
    table.remove(t, i)
  end
  return removed
end

M.split = function(s, sep)
  sep = sep or ','
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  s:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

-- JavaScript slice, but using Lua 1-based indexes
M.slice = function(t, begin, endExclusive)
  if type(t) == 'table' then
    local r = {}
    local end_
    if endExclusive == nil then
      end_ = #t
    else
      end_ = endExclusive - 1
    end
    for i=(begin or 1),end_ do
      r[#r+1] = t[i]
    end
    return r
  else
    return string.sub(t, begin)
  end
end

return M
