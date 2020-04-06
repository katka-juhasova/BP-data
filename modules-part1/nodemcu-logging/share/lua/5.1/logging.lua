Logger = {
}

function Logger:new (o, source_config)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.source = source_config or {}
  return o
end

function Logger:_log(priority, msg)
  event = {
    source = self.source,
    priority = priority,
    message = msg
  }
  print(cjson.encode(event))
  -- mqtt(event)
end

function Logger:debug(msg)
  self:_log("debug", msg)
end

function Logger:info(msg)
  self:_log("info", msg)
end

function Logger:notice(msg)
  self:_log("notice", msg)
end

function Logger:warn(msg)
  self:_log("warn", msg)
end

function Logger:crit(msg)
  self:_log("crit", msg)
end

function Logger:emerg(msg)
  self:_log("emerg", msg)
end

-- l = Logger:new(nil, { process = "test-module" } )
-- l:debug("a string")
-- l:debug({"key":"value"})
--

return Logger
