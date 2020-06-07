local Optional = {}
Optional.__index = Optional

function Optional.new(type, condition)
  local o = setmetatable({}, Optional)
  o.type = type
  if condition ~= nil then o.condition = condition else o.condition = true end
  return o
end

function Optional:decode(stream,parent)
  local condition = self.condition
  if type(condition) == "function" then condition = condition(parent) end

  if condition then return self.type:decode(stream, parent) end
end

function Optional:size(val, parent)
    local condition = self.condition
    if type(condition) == "function" then condition = condition(parent) end

    if condition then
      return self.type:size(val, parent)
    else
      return 0
    end
end


function Optional:encode(stream, val, parent)
  local condition = self.condition
  if type(condition) == "function" then condition = condition(parent) end

  if condition then self.type:encode(stream, val, parent) end
end

return Optional
