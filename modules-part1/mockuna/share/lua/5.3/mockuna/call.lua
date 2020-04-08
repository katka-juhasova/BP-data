-- contains what it was called with
-- calledWith

local call = {}
call.__index = call

function call:new(stub, method, ...)
    local c = setmetatable({}, call)
    c.args = {...}
    c.exactArgs = ...
    c.parent = stub.__originalParent
    c.index = stub.callCount
    c.method = method or stub.__originalFunction or function() end
    return c
end

function call:calledWith(...)
    local argsToCheck = {...}
    for k,v in ipairs(argsToCheck) do
        if self.args[k] ~= v then
            return false
        end
    end
    return true
end

function call:calledWithExactly(...)
    local argsToCheck = {...}
    for k,v in ipairs(self.args) do
        if argsToCheck[k] ~= v then
            return false
        end
    end
    return true
end

function call:call()
  local results = table.pack(pcall(function()
    return self.method(self.exactArgs)
  end))
  local ok, err = unpack(results)
  if not ok then
    self.exceptionMessage = err
  end
  table.remove(results, 1)
  self.results = results
  return unpack(results)
end

function call:returned(...)
  local returnsToCheck = {...}
  for k,v in ipairs(returnsToCheck) do
    if self.results[k] ~= v then
      return false
    end
  end
  return true
end

function call:returnedExactly(...)
  local returnsToCheck = {...}
  for k,v in ipairs(self.results) do
    if returnsToCheck[k] ~= v then
      return false
    end
  end
  return true
end

function call:threw(message)
  if message then
    if self.exceptionMessage:find(message) then
      return true
    else 
      return false
    end
  end

  if self.exceptionMessage then
    return true
  end
  return false
end

return call