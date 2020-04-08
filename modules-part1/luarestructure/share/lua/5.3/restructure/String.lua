local NumberT = require('restructure.Number').Number
local utils = require('restructure.utils')

local StringT = {}
StringT.__index = StringT

-- NOTE: encoding is stored just for informational purposes.
-- in Lua all strings are just a series of bytes.
function StringT.new(length, encoding)
  local b = setmetatable({}, StringT)
  b.length = length
  b.encoding = encoding or 'ascii'
  return b
end

function StringT:decode(stream, parent)
  local length
  if self.length then
    length = utils.resolveLength(self.length, stream, parent)
  end

  return stream:readString(length)
end

function StringT:size(val, parent)
  if not val then return utils.resolveLength(self.length, nil, parent) end
  local s
  s = #val
  if utils.instanceOf(self.length, NumberT) then s = s + self.length:size() end
  if not self.length then s = s + 1 end
  return s
end

function StringT:encode(stream, val)
  if utils.instanceOf(self.length, NumberT) then
    self.length:encode(stream, #val)
  end

  stream:writeString(val, #val)

  if not self.length then stream:writeUInt8(0x00) end
end

return StringT
