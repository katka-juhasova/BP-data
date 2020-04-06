local Client
do
  local _base_0 = {
    perform = function(self, worker_class, arguments, retry, queue)
      if arguments == nil then
        arguments = { }
      end
      if retry == nil then
        retry = false
      end
      if queue == nil then
        queue = 'default'
      end
      local key = self.key_generator.generate(queue, self.namespace)
      local message = self.messgae_serialiser.serialise(worker_class, arguments, retry)
      return self.redis:lpush(key, message)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, redis, namespace)
      self.redis = redis
      self.namespace = namespace
      local KeyGenerator = require('sidekiqjobpusher.key_generator')
      self.key_generator = KeyGenerator()
      local MessageSerialiser = require('sidekiqjobpusher.message_serialiser')
      self.messgae_serialiser = MessageSerialiser()
    end,
    __base = _base_0,
    __name = "Client"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Client = _class_0
  return _class_0
end
