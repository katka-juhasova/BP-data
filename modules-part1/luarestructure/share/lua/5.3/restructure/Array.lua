local NumberT = require('restructure.Number').Number
local utils = require('restructure.utils')

local ArrayT = {}
ArrayT.__index = ArrayT

function ArrayT.new(type, length, lengthType)
  local a = setmetatable({}, ArrayT)
  a.type = type
  a.length = length
  a.lengthType = lengthType or 'count'
  return a
end

function ArrayT:decode(stream, parent)
  local pos = stream.buffer.pos
  local res = {}
  local ctx = parent

  local length = nil
  if self.length ~= nil then
    length = utils.resolveLength(self.length, stream, parent)
  end

  if utils.instanceOf(self.length, NumberT) then
    res.parent = parent
    res._startOffset = pos
    res._currentOffset = 0
    res._length = length
    ctx = res
  end

  if not length or self.lengthType == 'bytes' then
    local target
    if length then
      target = stream.buffer.pos + length
    elseif parent and parent._length then
      target = parent._startOffset + parent._length
    else
      target = #stream.buffer.str -- FIXME exposing buffer internals here…ß
    end

    while stream.buffer.pos < target do
      table.insert(res, self.type:decode(stream, ctx))
    end
  else
    for _ = 1, length do
      table.insert(res, self.type:decode(stream, ctx))
    end
  end

  return res
end

function ArrayT:size(array, ctx)
  if not array then return self.type:size(ctx) * utils.resolveLength(self.length, nil, ctx) end

  local size = 0
  if utils.instanceOf(self.length, NumberT) then
    size = size + self.length:size()
    ctx = { parent = ctx }
  end

  for _, item in ipairs(array) do
    size = size + self.type:size(item, ctx)
  end

  return size
end

function ArrayT:encode(stream, array, parent)
  local ctx = parent
  if utils.instanceOf(self.length, NumberT) then
    ctx = {
      pointers =  {},
      startOffset = stream.buffer.pos,
      parent = parent
    }

    ctx.pointerOffset = stream.buffer.pos + self:size(array, ctx)
    self.length:encode(stream, #array)
  end

  for _,item in ipairs(array) do
    self.type:encode(stream, item, ctx)
  end

  if utils.instanceOf(self.length, NumberT) then
    local i = 1
    while i <= #ctx.pointers do
      local ptr = ctx.pointers[i]
      ptr.type:encode(stream, ptr.val)
      i = i + 1
    end
  end
end

return ArrayT
