local utils = require('restructure.utils')

local Pointer = {}
Pointer.__index = Pointer

local VoidPointer = {}
VoidPointer.__index = VoidPointer

function Pointer.new(offsetType, type, options)
  local p = setmetatable({}, Pointer)
  p.offsetType = offsetType
  p.options = options or {}
  p.type = type

  if p.type == 'void' then p.type = nil end

  if p.options.type == nil then p.options.type = 'local' end

  if p.options.allowNull == nil then p.options.allowNull= true end

  if p.options.nullValue == nil then p.options.nullValue = 0 end

  if p.options.lazy == nil then p.options.lazy = false end

  if p.options.relativeTo then
    p.relativeToGetter = function(ctx)
      local s = load(string.format("return ctx.%s",p.options.relativeTo), "ld", "bt", {ctx = ctx})
      return s()
    end
  end

  return p
end

function Pointer:decode(stream, ctx)
  local offset = self.offsetType:decode(stream, ctx)

  -- handle NULL pointers
  if offset == self.options.nullValue and self.options.allowNull then
    return nil
  end

  local relative
  if self.options.type == 'local' then
    relative = ctx._startOffset
  elseif self.options.type == 'immediate' then
    relative = stream.buffer.pos - self.offsetType:size()
  elseif self.options.typ == 'parent' then
    relative = ctx.parent._startOffset
  else -- global
      local c = ctx
      while c.parent do c = c.parent end
      relative = c._startOffset or 0
  end

  if self.options.relativeTo then relative = relative + self.relativeToGetter(ctx) end

  local ptr = offset + relative

  if self.type then
    local val = nil
    local decodeValue = function()
      if val ~= nil then return val end
      local pos = stream.buffer.pos
      stream.buffer.pos = ptr
      val = self.type:decode(stream, ctx)
      stream.buffer.pos = pos
      return val
    end

    -- If this is a lazy pointer, define a getter to decode only when needed.
    -- This obviously only works when the pointer is contained by a Struct.
    if self.options.lazy then
      return utils.PropertyDescriptor.new({get = decodeValue})
    end

    return decodeValue()
  else
    return ptr
  end
end

function Pointer:size(val, ctx)
  local parent = ctx
  if self.options.type == 'parent' then
    ctx = ctx.parent
  elseif self.options.type ~= 'local' and self.options.type ~= 'immediate' then
    while ctx.parent do ctx = ctx.parent end
  end

  local type = self.type
  if type == nil then
    if not utils.instanceOf(val, VoidPointer) then error("Must be a VoidPointer") end
    type = val.type
    val = val.value
  end


  if val and ctx then
    if not ctx.pointerSize then ctx.pointerSize = 0 end
    ctx.pointerSize = ctx.pointerSize + type:size(val, parent)
  end

  return self.offsetType:size()
end

function Pointer:encode(stream, val, ctx)
  local parent = ctx
  if not val then
    self.offsetType:encode(stream, self.options.nullValue)
    return
  end

  local relative
  if self.options.type == 'local' then
    relative = ctx.startOffset
  elseif self.options.type == 'immediate' then
    relative = stream.buffer.pos + self.offsetType:size(val, parent)
  elseif self.options.type == 'parent' then
    ctx = ctx.parent
    relative = ctx.startOffset
  else -- global
    relative = 0
    while ctx.parent do ctx = ctx.parent end
  end

  if self.options.relativeTo then
    relative = relative + self.relativeToGetter(parent.val)
  end

  self.offsetType:encode(stream, ctx.pointerOffset - relative)

  local type = self.type
  if type == nil then
    if not utils.instanceOf(val, VoidPointer) then
      error("Must be a VoidPointer")
    end
    type = val.type
    val = val.value
  end


  table.insert(ctx.pointers, {
    type = type,
    val = val,
    parent = parent
  })

  ctx.pointerOffset = ctx.pointerOffset + type:size(val, parent)
end

function VoidPointer.new(type, value)
  local v = setmetatable({}, VoidPointer)
  v.type = type
  v.value = value
  return v
end

local exports = {}

exports.Pointer = Pointer
exports.VoidPointer = VoidPointer

return exports
