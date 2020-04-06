
local Option = {}
Option.__index = Option

function new(val)
  local obj = {}
  setmetatable(obj, Option)

  obj.val = val
  return obj
end

function Option:is_some()
  return self.val ~= nil
end

function Option:is_none()
  return self.val == nil
end

function Option:expect(exception)
  assert( self:is_some(), exception or "Option is none!")
  return self.val
end

function Option:unwrap()
  return self.val
end

function Option:unwrap_or(default_value)
  if self:is_some() then
    return self.val
  end
  return default_value
end

function Option:unwrap_or_else(default_func)
  if self:is_some() then
    return self.val
  end
  return default_func()
end

function Option:fallback(alternate_value)
  local val = self:unwrap_or(alternate_value)
  return new(val)
end

function Option:match(is_some_func, is_none_func)
  if self:is_some() then
    return (type(is_some_func) == "function")
        and is_some_func(self:unwrap()) 
        or nil
  end
  return (type(is_none_func) == "function")
      and is_none_func()
      or nil
end


return new
