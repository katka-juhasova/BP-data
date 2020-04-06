local execute
execute = function(command, options)
  if options == nil then
    options = { }
  end
  return setmetatable({
    command = command,
    status = "unrun",
    code = false,
    signal = false,
    error_on_fail = options and options.error_on_fail or false,
    error_on_signal = options and options.error_on_signal or false,
    silent = options and options.silent or false
  }, {
    __call = function(self)
      if self.silent then
        command = self.command .. " > /dev/null 2> /dev/null"
      else
        command = self.command
      end
      local ok, sig = os.execute(command)
      local _exp_0 = ok
      if "exit" == _exp_0 then
        self.code = sig
        if (sig ~= 0) and self.error_on_fail then
          return error(tostring(command) .. " exited with code " .. tostring(code))
        end
      elseif "signal" == _exp_0 then
        self.signal = sig
        if self.error_on_signal then
          return error(tostring(command) .. " terminated with signal " .. tostring(signal))
        end
      end
    end
  })
end
local immediate
immediate = function(command, options)
  return (execute(command, options))()
end
local interact
interact = function(command)
  return {
    command = command,
    handle = false,
    open = function(self, mode)
      self.handle = io.popen(command, mode)
      if self.handle then
        return self.handle
      else
        return false
      end
    end,
    read = function(self, fmt)
      return self.handle:read(fmt)
    end,
    write = function(self, any)
      return self.handle:write(any)
    end,
    close = function(self)
      return self.handle:close()
    end
  }
end
local chain = setmetatable({ }, {
  __call = function(t, ...)
    local tree
    do
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = {
        ...
      }
      for _index_0 = 1, #_list_0 do
        local runnable = _list_0[_index_0]
        _accum_0[_len_0] = runnable
        _len_0 = _len_0 + 1
      end
      tree = _accum_0
    end
    return function()
      for _index_0 = 1, #tree do
        local runnable = tree[_index_0]
        runnable()
      end
    end
  end
})
return {
  execute = execute,
  interact = interact,
  immediate = immediate,
  chain = chain
}
