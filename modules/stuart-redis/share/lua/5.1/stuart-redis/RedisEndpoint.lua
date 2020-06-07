local stuart = require 'stuart'

local function getPassword(parsedUri)
  local atPos = string.find(parsedUri.authority, '@')
  if atPos then return string.sub(1, atPos) end
end

local function getDbNum(parsedUrl)
  return 0 -- TODO
end

local RedisEndpoint = stuart.class()

function RedisEndpoint:_init(host, port, auth, dbNum, timeout)
  self.host = host
  self.port = port
  self.auth = auth
  self.dbNum = dbNum or 0
  self.timeout = timeout or 2
end

function RedisEndpoint:connect()
  local has_redisClientLib, redisClientLib = pcall(require, 'redis')
  assert(has_redisClientLib)
  local redisClient = redisClientLib.connect(self.host, self.port)
  if self.auth then redisClient:auth(self.auth) end
  if self.dbNum > 0 then redisClient:select(self.dbNum) end
  return redisClient
end

function RedisEndpoint.newFromSparkConf(conf)
  function conf:getInt(key, defaultValue) return tonumber(conf:get(key, defaultValue)) end
  return RedisEndpoint.new(
    conf:get   ('spark.redis.host'),
    conf:getInt('spark.redis.port'),
    conf:get   ('spark.redis.auth'),
    conf:getInt('spark.redis.db'),
    conf:getInt('spark.redis.timeout')
  )
end

function RedisEndpoint.newFromURI(uri)
  local netUrl = require 'net.url'
  local parsedUri = netUrl.parse(uri)
  return RedisEndpoint.new(
    parsedUri.host,
    parsedUri.port,
    getPassword(parsedUri),
    getDbNum(parsedUri)
  )
end

return RedisEndpoint
