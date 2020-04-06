local Receiver = require 'stuart.streaming.Receiver'
local RedisConfig = require 'stuart-redis.RedisConfig'
local stuart = require 'stuart'

local PubSubReceiver = stuart.class(Receiver)

function PubSubReceiver:_init(ssc, channels)
  Receiver._init(self, ssc)
  self.channels = channels
end

function PubSubReceiver:onStart()
  self.log = require 'stuart.internal.logging'.log
  self.log:debug(string.format('Connecting to %s:%d',
    self.ssc.sc.conf:get('spark.redis.host'),
    self.ssc.sc.conf:get('spark.redis.port')
  ))
  local redisConf = RedisConfig.newFromSparkConf(self.ssc.sc:getConf())
  self.redisClient = redisConf:connection()
  if not self.redisClient:ping() then
    self.log:error(string.format('Error connecting to %s: %s', self.uri, self.err))
    return
  end
  self.log:info(string.format('Connected to %s', self.uri))
  self.subscriptionIterator = self.redisClient:pubsub({subscribe=self.channels})
end

function PubSubReceiver:onStop()
  if self.redisClient ~= nil then
    self.redisClient:unsubscribe(self.channel)
    self.redisClient:quit()
    self.redisClient = nil
  end
end

function PubSubReceiver:poll(durationBudget)
  local now = require 'stuart.interface'.now
  local startTime = now()
  local data = {}
  for message, abort in self.subscriptionIterator do
    if message ~= nil and message.kind == 'subscribe' then
      self.log:info(string.format('Subscribed to channel %s', message.channel))
    elseif message ~= nil and message.kind == 'message' then
      data[#data+1] = message.payload
    end
    local elapsed = now() - startTime
    if elapsed > durationBudget then break end
  end
  if #data == 0 then return nil end
  return {self.ssc.sc:makeRDD(data)}
end

return PubSubReceiver
