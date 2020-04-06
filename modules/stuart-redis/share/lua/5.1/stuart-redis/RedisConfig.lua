local stuart = require 'stuart'

local RedisConfig = stuart.class()

function RedisConfig:_init(initialHost)
  assert(stuart.istype(initialHost, require 'stuart-redis.RedisEndpoint'))
  self.initialHost = initialHost
end

function RedisConfig:connection()
  if self.pooledConn ~= nil then return self.pooledConn end
  self.pooledConn = self.initialHost:connect()
  return self.pooledConn
end

function RedisConfig:getAuth()
  return self.initialHost.auth
end

function RedisConfig:getDbNum()
  return self.initialHost.dbNum
end

function RedisConfig.newFromSparkConf(conf)
  local SparkConf = require 'stuart.SparkConf'
  assert(stuart.istype(conf, SparkConf))
  local RedisEndpoint = require 'stuart-redis.RedisEndpoint'
  return RedisConfig.new(RedisEndpoint.newFromSparkConf(conf))
end

return RedisConfig
