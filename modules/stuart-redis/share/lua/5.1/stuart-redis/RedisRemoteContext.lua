local RedisConfig = require 'stuart-redis.RedisConfig'
local RedisContext = require 'stuart-redis.RedisContext'
local stuart = require 'stuart'

local RedisRemoteContext = stuart.class(RedisContext)

function RedisRemoteContext:filterKeysByType(conn, keys, typeFilter)
  local res = {}
  for _, key in ipairs(keys) do
    local type = conn:type(key)
    if type == typeFilter then res[#res+1] = key end
  end
  return res
end

function RedisRemoteContext:foreachWithPipeline(redisConf, items, f)
  local conn = redisConf:connection()
  
  -- Pipelines are broke with Lua 5.2; see https://github.com/nrk/redis-lua/issues/43
  --
  -- local replies, count = conn:pipeline(function(pipeline)
  --   for _, item in ipairs(items) do
  --     f(pipeline, item)
  --   end
  -- end)
  
  for _, kv in ipairs(items) do
    f(conn, kv)
  end
  
end

function RedisRemoteContext:fromRedisHash(keysOrKeyPattern, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  local hashKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'hash')
  local res = {}
  for _, hashKey in ipairs(hashKeys) do
    local kvs = conn:hgetall(hashKey)
    for k,v in pairs(kvs) do
      res[#res+1] = {k, v}
    end
  end
  return self:parallelize(res, numPartitions)
end

function RedisRemoteContext:fromRedisKV(keysOrKeyPattern, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local keys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'string')
    local res = {}
    for _, key in ipairs(keys) do
      local value = conn:get(key)
      res[#res+1] = {key, value}
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisList(keysOrKeyPattern, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local listKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'list')
    local res = {}
    for _, listKey in ipairs(listKeys) do
      local values = conn:lrange(listKey, 0, -1)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisSet(keysOrKeyPattern, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local setKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'set')
    local res = {}
    for _, setKey in ipairs(setKeys) do
      local values = conn:smembers(setKey)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisZRange(keysOrKeyPattern, startRange, endRange, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local zsetKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local values = conn:zrange(zsetKey, startRange, endRange)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisZRangeByScore(keysOrKeyPattern, startScore, endScore, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local zsetKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local values = conn:zrangebyscore(zsetKey, startScore, endScore)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisZRangeByScoreWithScore(keysOrKeyPattern, startScore, endScore, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local zsetKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local kvs = conn:zrangebyscore(zsetKey, startScore, endScore, 'WITHSCORES')
      for _, kv in ipairs(kvs) do
        res[#res+1] = {kv[1], tonumber(kv[2])}
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisZRangeWithScore(keysOrKeyPattern, startRange, endRange, numPartitions)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  local conn = redisConf:connection()
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local zsetKeys = self:filterKeysByType(conn, conn:keys(keysOrKeyPattern), 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local kvs = conn:zrange(zsetKey, startRange, endRange, 'WITHSCORES')
      for _, kv in ipairs(kvs) do
        res[#res+1] = {kv[1], tonumber(kv[2])}
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisRemoteContext:fromRedisZSet(keysOrKeyPattern, numPartitions)
  return self:fromRedisZRange(keysOrKeyPattern, 0, -1, numPartitions)
end

function RedisRemoteContext:fromRedisZSetWithScore(keysOrKeyPattern, numPartitions)
  return self:fromRedisZRangeWithScore(keysOrKeyPattern, 0, -1, numPartitions)
end

function RedisRemoteContext:setHash(hashName, data, ttl, redisConf)
  self:foreachWithPipeline(redisConf, data, function(pipeline, item)
    local k, v = item[1], item[2]
    pipeline:hset(hashName, k, v)
    if ttl and ttl > 0 then
      pipeline:expire(hashName, ttl)
    end
  end)
end

function RedisRemoteContext:setKVs(data, ttl, redisConf)
  self:foreachWithPipeline(redisConf, data, function(pipeline, item)
    local k, v = item[1], item[2]
    if ttl and ttl > 0 then
      pipeline:setex(k, ttl, v)
    else
      pipeline:set(k, v)
    end
  end)
end

function RedisRemoteContext:setList(listName, data, ttl, redisConf)
  self:foreachWithPipeline(redisConf, data, function(pipeline, v)
    pipeline:rpush(listName, v)
    if ttl and ttl > 0 then
      pipeline:expire(listName, ttl)
    end
  end)
end

function RedisRemoteContext:setSet(setName, data, ttl, redisConf)
  self:foreachWithPipeline(redisConf, data, function(pipeline, v)
    pipeline:sadd(setName, v)
    if ttl and ttl > 0 then
      pipeline:expire(setName, ttl)
    end
  end)
end

function RedisRemoteContext:setZset(zsetName, data, ttl, redisConf)
  self:foreachWithPipeline(redisConf, data, function(pipeline, item)
    local k, v = item[1], tonumber(item[2])
    pipeline:zadd(zsetName, tonumber(v), k)
    if ttl and ttl > 0 then
      pipeline:expire(zsetName, ttl)
    end
  end)
end

function RedisRemoteContext:toRedisHASH(keyValuesRDD, hashName, ttl)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  keyValuesRDD:foreachPartition(function(data)
    self:setHash(hashName, data, ttl, redisConf)
  end)
end

function RedisRemoteContext:toRedisKV(keyValuesRDD, ttl)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  keyValuesRDD:foreachPartition(function(data)
    self:setKVs(data, ttl, redisConf)
  end)
end

function RedisRemoteContext:toRedisLIST(valuesRDD, listName, ttl)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  valuesRDD:foreachPartition(function(data)
    self:setList(listName, data, ttl, redisConf)
  end)
end

function RedisRemoteContext:toRedisSET(valuesRDD, setName, ttl)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  valuesRDD:foreachPartition(function(data)
    self:setSet(setName, data, ttl, redisConf)
  end)
end

function RedisRemoteContext:toRedisZSET(valuesRDD, setName, ttl)
  local redisConf = RedisConfig.newFromSparkConf(self:getConf())
  valuesRDD:foreachPartition(function(data)
    self:setZset(setName, data, ttl, redisConf)
  end)
end

return RedisRemoteContext
