local format
format = function(str, fmt)
  for k, v in pairs(fmt) do
    str = str:gsub("%$" .. tostring(k), tostring(v))
  end
  return str
end
local clear
clear = function(str)
  return str:gsub("%$[a-zA-Z0-9]+", "")
end
local check
check = function(f)
  return function(...)
    local args = {
      ...
    }
    for i, arg in ipairs(args) do
      assert(("string" == type(arg)), "argument #" .. tostring(i) .. " is not a string")
    end
    return f(...)
  end
end
local formCommand
formCommand = function(cmd, argl)
  local addLast = { }
  for _index_0 = 1, #argl do
    local arg = argl[_index_0]
    local _exp_0 = type(arg)
    if "string" == _exp_0 or "number" == _exp_0 or "boolean" == _exp_0 then
      cmd = cmd .. " " .. tostring(arg)
    elseif "table" == _exp_0 then
      if arg[1] then
        if arg.__last then
          table.insert(addLast, arg)
        else
          for _index_1 = 1, #arg do
            local ar = arg[_index_1]
            cmd = cmd .. " " .. tostring(ar)
          end
        end
      else
        cmd = format(cmd, arg)
      end
    else
      error("runkit $ invalid type passed to command")
    end
  end
  for _index_0 = 1, #addLast do
    local arg = addLast[_index_0]
    cmd = cmd .. " " .. tostring(arg)
  end
  return clear(cmd)
end
local is_windows = "\\" == package.config:sub(1, 1)
local SILENT
if is_windows then
  SILENT = {
    ">nul 2>nul",
    __last = true
  }
else
  SILENT = {
    ">/dev/null 2>/dev/null",
    __last = true
  }
end
local REDIRECT_STDERR = {
  "2>&1",
  __last = true
}
local command = check(function(cmd)
  return function(...)
    cmd = formCommand(cmd, {
      ...
    })
    local ok, mode, signal = os.execute(cmd)
    return (ok or false), mode, signal
  end
end)
local capture = check(function(cmd)
  return function(...)
    cmd = formCommand(cmd, {
      ...
    })
    local result
    do
      local _with_0 = io.popen(cmd, "r")
      result = _with_0:read("*a")
      _with_0:close()
    end
    return result
  end
end)
local interact
interact = function(cmd)
  return function(...)
    cmd = formCommand(cmd, {
      ...
    })
    return {
      command = cmd
    }
  end
end
local popenC
popenC = function(self, mode)
  self.handle = io.popen(self.command, mode)
end
local readC
readC = function(self, format)
  if format == nil then
    format = "r"
  end
  if self.rhandle then
    return self.rhandle:read(format)
  else
    return self.handle and (self.handle:read(format)) or error("handle does not exist")
  end
end
local readAllC
readAllC = function(self)
  return self.handle and (self.handle:read("*a")) or error("handle does not exist")
end
local writeC
writeC = function(self, str)
  return self.handle and (self.handle:write(str)) or error("handle does not exist")
end
local closeC
closeC = function(self)
  if self.rhandle then
    self.rhandle:close()
  end
  return self.handle and self.handle:close() or error("handle does not exist")
end
return {
  silence = silence,
  command = command,
  capture = capture,
  interact = interact,
  popenC = popenC,
  readC = readC,
  readAllC = readAllC,
  writeC = writeC,
  closeC = closeC
}
