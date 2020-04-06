local Sink
Sink = require("debugkit.log").Sink
local safeOpen, getSize
do
  local _obj_0 = require("filekit")
  safeOpen, getSize = _obj_0.safeOpen, _obj_0.getSize
end
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
local sink = { }
local encode
do
  local ok, json = pcall(function()
    return require("cjson")
  end)
  if ok then
    encode = json.encode
  end
  ok, json = pcall(function()
    return require("dkjson")
  end)
  if ok then
    encode = json.encode
  end
  ok, json = pcall(function()
    return require("json")
  end)
  if ok then
    encode = json.encode
  else
    local _
    _ = function()
      return 404
    end
  end
end
sink.json = function()
  return Sink({
    write = function(self, L, tag, level, msg)
      local data = {
        name = L.name,
        level = L.level,
        time = L.time(),
        date = L.date(),
        exclude = L.exclude,
        flag = self.flag
      }
      msg = encode({
        message = msg,
        level = level,
        data = data,
        tag = tag
      })
      if (msg == 404) or (msg == nil) then
        return 
      end
      if (L.levels[level] >= L.levels[L.level]) and (not contains(tag, L.exclude)) then
        return io.write(msg)
      end
    end
  })
end
sink.rollingFile = function(file, size)
  if size == nil then
    size = 1000000
  end
  return Sink({
    open = function(self, f)
      if f == nil then
        f = file
      end
      self.flag.current = f
      if not (self.flag.opened) then
        local fh = safeOpen(f, "a")
        if fh.error then
          error("sink.rollingFile $ could not open file " .. tostring(f) .. "!")
        end
        self.fh, self.flag.opened = fh, true
      end
      if not (self.flag.initialized) then
        self.flag.size = self.flag.size or size
        self.flag.filename = self.flag.filename or file
        self.flag.count = self.flag.count or 0
        self.flag.initialized = true
      end
    end,
    write = function(self, L, tag, level, msg)
      if self.flag.opened then
        if ((getSize(self.flag.current)) + #msg) < self.flag.size then
          if (L.levels[level] >= L.levels[L.level]) and (not contains(tag, L.exclude)) then
            return self.fh:write(msg)
          end
        else
          self:close()
          self.flag.count = self.flag.count + 1
          self:open(tostring(self.flag.filename) .. "." .. tostring(self.flag.count))
          return self:write(L, level, msg)
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
return sink
