local BooleanT = {}
BooleanT.__index = BooleanT

function BooleanT.new(type)
  local b = setmetatable({}, BooleanT)
  b.type = type
  return b
end

function BooleanT:decode(stream, parent)
  if self.type:decode(stream, parent) == 0 then return false else return true end
end

function BooleanT:size(val, parent)
  return self.type:size(val, parent)
end

function BooleanT:encode(stream, val, parent)
  self.type:encode(stream, val and 1 or 0, parent)
end

return BooleanT