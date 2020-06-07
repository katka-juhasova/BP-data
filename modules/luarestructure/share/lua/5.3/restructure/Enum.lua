local Enum = {}
Enum.__index = Enum

function Enum.new(type, options)
  local e = setmetatable({}, Enum)
  e.type = type
  e.options = options or {}
  return e
end

function Enum:decode(stream)
  local index = self.type:decode(stream)
  return self.options[index + 1] or index
end

function Enum:size()
  return self.type:size()
end

function Enum:encode(stream, val)
  local index = -1
  for i,v in ipairs(self.options) do
    if v == val then
      index = i - 1
      break
    end
  end

  if index == -1 then error(string.format("Unknown option in enum: %s",val)) end

  self.type:encode(stream, index)
end

return Enum
