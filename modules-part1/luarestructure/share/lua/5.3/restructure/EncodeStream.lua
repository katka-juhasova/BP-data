local vstruct = require('vstruct')
local DecodeStream = require('restructure.DecodeStream')

local EncodeStream = {}
EncodeStream.__index = EncodeStream

function EncodeStream.new()
  local e = {}
  setmetatable(e, EncodeStream)
  e.buffer = vstruct.cursor("")
  return e
end

local function getWriterFunc(fmt)
  return function(self, data)
    return vstruct.write(fmt, self.buffer, {data})
  end
end

for k,fmt in pairs(DecodeStream.types) do
  EncodeStream["write"..k] = getWriterFunc(fmt)
end

function EncodeStream:flush()
  self.buffer:flush()
end

function EncodeStream:writeBuffer(buffer)
  vstruct.write("s", self.buffer, {buffer})
end

function EncodeStream:writeString(buffer)
  vstruct.write("s", self.buffer, {buffer})
end

function EncodeStream:fill(val, length)
  local fmt = 'x'..length..','..val
  vstruct.write(fmt, self.buffer,{})
end

function EncodeStream:getContents()
  self:flush()
  return self.buffer.str
end

return EncodeStream