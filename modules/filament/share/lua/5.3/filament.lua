local path = (...):match("(.-)[^%.]+$")
local thread, filesystem
do
  local _obj_0 = love
  thread, filesystem = _obj_0.thread, _obj_0.filesystem
end
local fn
fn = function(...)
  local opts = ...
  if opts.modules then
    for mod in opts.modules:gmatch("[^,]+") do
      require(mod)
    end
  end
  return loadstring(opts.fn:getString())(opts)
end
fn = filesystem.newFileData(string.dump(fn), "filament.thread")
local next_id = 0
local Filament
do
  local _class_0
  local _base_0 = {
    start = function(self)
      return self.thread:start(opts)
    end,
    push = function(self, ...)
      if 1 < select("#", ...) then
        return self.input:push({
          ...
        })
      else
        return self.input:push(...)
      end
    end,
    pop = function(self)
      return self.output:pop()
    end,
    supply = function(self, ...)
      if 1 < select("#", ...) then
        return self.input:supply({
          ...
        })
      else
        return self.input:supply(...)
      end
    end,
    demand = function(self)
      return self.output:demand()
    end,
    peek = function(self)
      return self.output:peek()
    end,
    getError = function(self)
      return self.thread:getError()
    end,
    isRunning = function(self)
      return self.thread:isRunning()
    end,
    wait = function(self)
      return self.thread:wait()
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      local _exp_0 = type(opts)
      if "string" == _exp_0 or "function" == _exp_0 then
        opts = {
          fn = opts
        }
      end
      local _exp_1 = type(opts.fn)
      if "string" == _exp_1 then
        opts.fn = filesystem.newFileData(opts.fn, "filament.fn")
      elseif "function" == _exp_1 then
        opts.fn = filesystem.newFileData(string.dump(opts.fn), "filament.fn")
      end
      if not (opts.input) then
        opts.input = thread.getChannel(self.__class:id())
      end
      if not (opts.output) then
        opts.output = thread.getChannel(self.__class:id())
      end
      self.opts = opts
      self.input = opts.input
      self.output = opts.output
      self.thread = thread.newThread(fn)
    end,
    __base = _base_0,
    __name = "Filament"
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
  self.run = function(...)
    local filament = Filament(...)
    filament:start()
    return filament
  end
  self.id = function()
    next_id = next_id + 1
    return next_id
  end
  Filament = _class_0
  return _class_0
end
