local utils = require('restructure.utils')
local NumberT = require('restructure.Number').Number

local BufferT = {}
BufferT.__index = BufferT

function BufferT.new(length)
  local b = setmetatable({}, BufferT)
  b.length = length
  return b
end

function BufferT:decode(stream, parent)
  local length = utils.resolveLength(self.length, stream, parent)
  return stream:readBuffer(length)
end

function BufferT:size(val, parent)
  if val then return #val end

  return utils.resolveLength(self.length, nil, parent)
end

function BufferT:encode(stream, buf)
  if utils.instanceOf(self.length, NumberT) then
    self.length:encode(stream, #buf)
  end

  stream:writeBuffer(buf)
end

return BufferT
