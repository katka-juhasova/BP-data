--Initialize global context from config
local function context(self, context)
  for name, config in pairs(context) do
    if not config then
      name = config
      config = {}
    end
    self:addContext(name, config)
  end
end

--registers all subscribers specified in config
local function subscribers(self, subscribers)
  for serializedChannel, list in pairs(subscribers) do
    local channel = {}
    string.gsub(serializedChannel, "([^:]+)", function(c) channel[#channel+1] = c end)
    for subscriber, config in pairs(list) do
      if type(subscriber) == "number" then
        if type(config) == "table" then
          for key, value in pairs(config) do
            subscriber = key
            config = value
          end
        else
          subscriber = config
          config = {}
        end
      end
      self:subscribe(channel, subscriber, config)
    end
  end
end

--register all publishers specified in config
local function publishers(self, publishers)
  self.publishers = publishers
end

return function(lusty, config)
  subscribers(lusty, config.subscribers)
  publishers(lusty, config.publishers)
  context(lusty, config.context)
  lusty.context.global = config.global
end
