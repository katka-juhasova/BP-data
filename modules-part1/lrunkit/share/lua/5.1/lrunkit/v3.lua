local command
command = function(cmd)
  if (type(cmd)) ~= "string" then
    error("lrunkit $ `cmd` is not a string")
  end
  return function(...)
    local argl = {
      ...
    }
    for _index_0 = 1, #argl do
      local arg = argl[_index_0]
      cmd = cmd .. " " .. tostring(arg)
    end
    local mode, signal = os.execute(cmd)
    return signal
  end
end
local capture
capture = function(cmd)
  if (type(cmd)) ~= "string" then
    error("lrunkit $ `cmd` is not a string")
  end
  return function(...)
    local argl = {
      ...
    }
    for _index_0 = 1, #argl do
      local arg = argl[_index_0]
      cmd = cmd .. " " .. tostring(arg)
    end
    local result
    do
      local _with_0 = io.popen(cmd, "r")
      result = handle:read("*a")
      _with_0:close()
    end
    return result
  end
end
local interact
interact = function(cmd)
  if (type(cmd)) ~= "string" then
    error("lrunkit $ `cmd` is not a string")
  end
  return function(...)
    local argl = {
      ...
    }
    for _index_0 = 1, #argl do
      local arg = argl[_index_0]
      cmd = cmd .. " " .. tostring(arg)
    end
    return {
      command = cmd,
      handle = { },
      open = function(self, mode)
        self.handle = io.popen(self.command, mode)
        return self.handle or false
      end,
      read = function(self, frmt)
        return self.handle:read(frmt)
      end,
      write = function(self, any)
        return self.handle:write(any)
      end,
      close = function(self)
        return self.handle:close()
      end
    }
  end
end
return {
  command = command,
  capture = capture,
  interact = interact
}
