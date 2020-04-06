local style
style = require("ansikit.style").style
local safeOpen
safeOpen = require("filekit").safeOpen
local levels
levels = function(t)
  local _tbl_0 = { }
  for i, v in ipairs(t) do
    _tbl_0[v] = i
  end
  return _tbl_0
end
local inverse = levels
local _cache_contains = { }
local contains
contains = function(e, t)
  if not (_cache_contains[t]) then
    _cache_contains[t] = inverse(t)
  end
  return _cache_contains[t][e] and true or false
end
local Sink
Sink = function(self)
  return setmetatable({
    flag = self.flag or { },
    open = self.open or function() end,
    write = self.write or function() end,
    close = self.close or function() end
  }, {
    __type = "Sink"
  })
end
local sink = { }
sink.null = function()
  return Sink()
end
sink.all = function()
  return Sink({
    write = function(self, L, tag, level, msg)
      return print(msg)
    end
  })
end
sink.print = function()
  return Sink({
    write = function(self, L, tag, level, msg)
      if (L.levels[level] >= L.levels[L.level]) and (not contains(tag, L.exclude)) then
        return print(msg)
      end
    end
  })
end
sink.write = function()
  return Sink({
    write = function(self, L, tag, level, msg)
      if (L.levels[level] >= L.levels[L.level]) and (not contains(tag, L.exclude)) then
        return io.write(msg)
      end
    end
  })
end
sink.file = function(file)
  return Sink({
    open = function(self)
      if not (self.flag.opened) then
        local fh = safeOpen(file, "a")
        if fh.error then
          error("sink.file $ could not open file " .. tostring(file) .. "!")
        end
        self.fh, self.flag.opened = fh, true
      end
    end,
    write = function(self, L, tag, level, msg)
      if self.flag.opened then
        if (L.levels[level] >= L.levels[L.level]) and (not contains(tag, L.exclude)) then
          return self.fh:write(msg)
        end
      else
        return error("sink.file $ sink is not open!")
      end
    end,
    close = function(self)
      if self.flag.opened then
        self.fh:close()
        self.flag.opened = false
      end
    end
  })
end
local Logger
Logger = function(self)
  self.color = self.color or true
  self.name = self.name or ""
  self.sink = self.sink or sink.write()
  self.level = self.level or "all"
  self.levels = self.levels or levels({
    "none",
    "all"
  })
  self.time = self.time or function(self)
    return os.date("%X")
  end
  self.date = self.date or function(self)
    return ""
  end
  self.header = self.header or function(self, t, l)
    return tostring(self:time()) .. " " .. tostring(self.name) .. " " .. tostring(self.level) .. " "
  end
  self.footer = self.footer or function(self, t, l)
    return "\n"
  end
  self.exclude = self.exclude or {
    "hide"
  }
  self.open = function(self)
    return self.sink:open()
  end
  self.close = function(self)
    return self.sink:close()
  end
  return setmetatable(self, {
    __call = function(t, level)
      if level == nil then
        level = "all"
      end
      self:open()
      return function(tag, msg)
        if not msg then
          return self.sink:write(self, "show", level, tostring(self:header("show", level)) .. tostring(tag) .. tostring(self:footer(tag, level)))
        else
          return self.sink:write(self, tag, level, tostring(self:header(tag, level)) .. tostring(msg) .. tostring(self:footer(tag, level)))
        end
      end
    end,
    __type = "Logger"
  })
end
local logger = { }
logger.minimal = function()
  return Logger({
    _count = 0,
    name = "log",
    header = function(self)
      self._count = self._count + 1
      return self.color and (style("%{white bold}" .. tostring(self._count) .. " %{yellow}$ ")) or tostring(self._count) .. " $ "
    end
  })
end
logger.default = function()
  return Logger({
    name = "default",
    sink = sink.write(),
    level = "all",
    levels = levels({
      "none",
      "all"
    }),
    time = function(self)
      return os.date("%X")
    end,
    date = function(self)
      return ""
    end,
    color = true,
    footer = function(self)
      return "\n"
    end,
    header = function(self)
      return self.color and (style("%{white bold}" .. tostring(self:time()) .. " %{green}" .. tostring(self.name) .. " ")) or tostring(self:time()) .. " " .. tostring(self.name)
    end
  })
end
return {
  Sink = Sink,
  sink = sink,
  Logger = Logger,
  logger = logger,
  levels = levels
}
