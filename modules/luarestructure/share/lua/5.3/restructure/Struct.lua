local utils = require('restructure.utils')

local Struct = {}
Struct.__index = Struct

function Struct.new(fields)
  local a = setmetatable({}, Struct)
  a.fields = fields or {}
  return a
end

function Struct:decode(stream, parent, length)
  length = length or 0
  local res = Struct._setup(stream, parent, length)
  Struct._parseFields(stream, res, self.fields)
  if self.process then self.process(res, stream) end
  return res
end

function Struct._setup(stream, parent, length)
  local res = {}
  setmetatable(res, {
    __index = {
      parent         = parent,
      _startOffset   = stream.buffer.pos,
      _currentOffset = 0,
      _length        = length
    }
  })
  return res
end

function Struct._parseFields(stream, res, fields)
  for _,t in ipairs(fields) do
    local key, type_
    for j,u in pairs(t) do
      key = j
      type_ = u
    end

    local val
    if type(type_) == "function" then
      val = type_(res)
    else
      val = type_:decode(stream, res)
    end

    if val ~= nil then
      if utils.instanceOf(val, utils.PropertyDescriptor) then
        -- FIXME: ugly hack to implement Javascript like lazy getter
        -- It’s probably much better to rethink this to make it more
        -- Lua-ish
        local mt = getmetatable(res).__index
        local lazygetter = {
          __index =  function(_, k)

              if k == key then return val.get() end
            end}
        setmetatable(mt, lazygetter)
        -- error("NOT IMPLEMENTED")
      else
        res[key] = val
      end
    end
    getmetatable(res)._currentOffset = stream.buffer.pos - res._startOffset
  end
  return
end

function Struct:size(val, parent, includePointers)
  val = val or {}
  if includePointers == nil then includePointers = true end

  local ctx = {
    parent = parent,
    val = val,
    pointerSize = 0
  }

  local size = 0
  for _,t in ipairs(self.fields) do
    local key, type_
    for j,u in pairs(t) do
      key = j
      type_ = u
    end
    if type_.size then
      size = size + type_:size(val[key], ctx)
    end
  end

  if includePointers then size = size + ctx.pointerSize end

  return size
end

function Struct:encode(stream, val, parent)
  if self.preEncode then self.preEncode(val, stream) end

  local ctx = {
    pointers = {},
    startOffset = stream.buffer.pos,
    parent = parent,
    val = val,
    pointerSize = 0
  }

  ctx.pointerOffset = stream.buffer.pos + self:size(val, ctx, false)

  for _,t in ipairs(self.fields) do
    local key, type_
    for j,u in pairs(t) do
      key = j
      type_ = u
    end
    if type_.encode then
      type_:encode(stream, val[key], ctx)
    end
  end

  local i = 1
  while i <= #ctx.pointers do
    local ptr = ctx.pointers[i]
    ptr.type:encode(stream, ptr.val, ptr.parent)
    i = i + 1
  end
  return
end

return Struct
