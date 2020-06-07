local ArrayT = require('restructure.Array')
local NumberT = require('restructure.Number').Number
local utils = require('restructure.utils')

local LazyArray = {}
LazyArray.__index = LazyArray

local LazyArrayT = {}
LazyArrayT.__index = LazyArrayT
setmetatable(LazyArrayT, ArrayT)

function LazyArrayT.new(...)
  local a = ArrayT.new(...)
  setmetatable(a, LazyArrayT)
  return a
end

function LazyArrayT:decode(stream, parent)
  local pos = stream.buffer.pos
  local length = utils.resolveLength(self.length, stream, parent)

  if utils.instanceOf(length, NumberT) then
    parent = {
      parent = parent,
      _startOffset = pos,
      _currentOffset = 0,
      _length = length
    }
  end

  local res = LazyArray.new(self.type, length, stream, parent)

  return res
end

function LazyArrayT:size(val, ctx)
  if utils.instanceOf(val,LazyArray) then val = val:toArray() end

  return ArrayT.size(self, val, ctx)
end

function LazyArrayT:encode(stream, val, ctx)
    if utils.instanceOf(val, LazyArray) then val = val:toArray() end

    return ArrayT.encode(self, stream, val, ctx)
end

function LazyArray.new(type, length, stream, ctx)
  local a = setmetatable({}, LazyArray)
  a.type = type
  a.length = length
  a.stream = stream
  a.ctx = ctx
  a.base = a.stream.buffer.pos
  a.items = {}
  return a
end

function LazyArray:get(index)
  if index < 0 or index >= self.length then return nil end

    if not self.items[index + 1] then
      local pos = self.stream.buffer.pos
      self.stream.buffer.pos = self.base + self.type:size(nil, self.ctx) * index
      self.items[index + 1] = self.type:decode(self.stream, self.ctx)
      self.stream.buffer.pos = pos
    end

  return self.items[index + 1]
end

function LazyArray:toArray()
  local a = {}
  for i = 1, self.length do
    a[i] = self:get(i - 1)
  end
  return a
end

return LazyArrayT
