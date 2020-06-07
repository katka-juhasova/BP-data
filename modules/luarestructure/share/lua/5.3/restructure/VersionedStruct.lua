local Struct = require('restructure.Struct')
local utils = require('restructure.utils')

local VersionedStruct = setmetatable({}, Struct)
VersionedStruct.__index = VersionedStruct

function VersionedStruct.new(type_, versions)
  local v = setmetatable({}, VersionedStruct)
  v.type_ = type_
  v.versions = versions or {}

  if type(v.type_) == 'string' then
    v.versionGetter = function(parent)
      return parent[v.type_]
    end

    v.versionSetter = function(parent, version)
      parent[v.type_] = version
    end
  end

  return v
end

function VersionedStruct:decode(stream, parent, length)
  length = length or 0
  local res = self._setup(stream, parent, length)

  if type(self.type_) == 'string' then
    res.version = self.versionGetter(parent)
  else
    res.version = self.type_:decode(stream)
  end

  if self.versions.header then
    self._parseFields(stream, res, self.versions.header)
  end

  local fields = self.versions[res.version]
  if not fields then error(string.format("Unknown version %s", res.version)) end

  if utils.instanceOf(fields, VersionedStruct) then return fields:decode(stream, parent) end

  self._parseFields(stream, res, fields)

  if self.process then self.process(res, stream) end

  return res
end

function VersionedStruct:size(val, parent, includePointers)
  if not val then error('Not a fixed size') end
  if includePointers == nil then includePointers = true end

  local ctx = {
    parent = parent,
    val = val,
    pointerSize = 0
  }

  local size = 0
  if type(self.type_) ~= 'string' then
    size = size + self.type_:size(val.version, ctx)
  end

  if self.versions.header then
    for _,t in ipairs(self.versions.header) do
      local key, type_
      for j,u in pairs(t) do
        key = j
        type_ = u
      end
      if type_.size then
        size = size + type_:size(val[key], ctx)
      end
    end
  end

  local fields = self.versions[val.version]
  if not fields then error(string.format("Unknown version %s", val.version)) end

  for _,t in ipairs(fields) do
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

function VersionedStruct:encode(stream, val, parent)
  if self.preEncode then self.preEncode(val, stream) end

  local ctx = {
    pointers = {},
    startOffset = stream.buffer.pos,
    parent = parent,
    val = val,
    pointerSize = 0
  }

  ctx.pointerOffset = stream.buffer.pos + self:size(val, ctx, false)

  if type(self.type_) ~= 'string' then self.type_:encode(stream, val.version) end

  if self.versions.header then
    for _,t in ipairs(self.versions.header) do
      local key, type_
      for j,u in pairs(t) do
        key = j
        type_ = u
      end
      if type_.encode then
        type_:encode(stream, val[key], ctx)
      end
    end
  end

  local fields = self.versions[val.version]
  for _,t in ipairs(fields) do
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



return VersionedStruct
