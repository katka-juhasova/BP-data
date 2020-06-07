local Emitter, off, once_mt, no_warnings, trace_warnings, fallbacks
do
  local _class_0
  local _base_0 = {
    emit = function(self, name, ...)
      local listeners = self.events[name]
      if listeners == nil then
        local listener = fallbacks[name]
        if listener then
          listener(...)
        end
        return self
      end
      local current = listeners
      local len
      listeners, len = { }, 0
      for i = 1, current.len do
        local _continue_0 = false
        repeat
          local listener = current[i]
          if listener == false then
            _continue_0 = true
            break
          end
          if off ~= listener(...) then
            listener = current[i]
            if listener ~= false then
              len = len + 1
              listeners[len] = listener
            end
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      if len > 0 then
        self.events[name] = listeners
        listeners.len = len
        return self
      end
      self.events[name] = nil
      return self
    end,
    on = function(self, name, listener)
      local listeners = self.events[name]
      if listeners == nil then
        listeners = {
          len = 1
        }
        self.events[name] = listeners
      else
        listeners.len = listeners.len + 1
      end
      local len
      len = listeners.len
      listeners[len] = listener
      return self
    end,
    once = function(self, name, listener)
      return self:on(name, setmetatable({
        emitter = self,
        name = name,
        listener = listener
      }, once_mt))
    end,
    off = function(self, ...)
      local name, listener = ...
      if select('#', ...) == 1 then
        self.events[name] = nil
        return self
      end
      local listeners = self.events[name]
      if listeners ~= nil then
        local len
        len = listeners.len
        for i, item in ipairs(listeners) do
          local _continue_0 = false
          repeat
            do
              if type(item) == 'function' then
                if item ~= listener then
                  _continue_0 = true
                  break
                end
              elseif item.listener ~= listener then
                _continue_0 = true
                break
              end
              if len > 1 then
                listeners.len = len - 1
                listeners[i] = false
                break
              end
              self.events[name] = nil
              break
            end
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        return self
      end
      return self
    end,
    len = function(self, name)
      local listeners = self.events[name]
      if listeners == nil then
        return 0
      end
      return listeners.len
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.events = { }
    end,
    __base = _base_0,
    __name = "Emitter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.setFallback = function(name, listener)
    fallbacks[name] = listener
  end
  Emitter = _class_0
end
off = { }
once_mt = {
  __call = function(self, ...)
    self.listener(...)
    return off
  end
}
no_warnings = os.getenv('NO_WARNINGS')
trace_warnings = os.getenv('TRACE_WARNINGS')
fallbacks = {
  error = function(...)
    print(table.concat({
      'error:',
      ...
    }, ' '))
    return print(debug.traceback())
  end,
  warn = (function()
    if not no_warnings then
      return function(...)
        print(table.concat({
          'warn:',
          ...
        }, ' '))
        if trace_warnings then
          return print(debug.traceback())
        end
      end
    end
  end)()
}
return Emitter