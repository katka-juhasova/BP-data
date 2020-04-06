local RedisContext = require 'stuart-redis.RedisContext'
local stuart = require 'stuart'

local RedisEmbeddedContext = stuart.class(RedisContext)

function RedisEmbeddedContext:filterKeysByType(keys, typeFilter)
  local res = {}
  for _, key in ipairs(keys) do
    local typeRes = redis.call('TYPE', key)
    local type = typeRes['ok']
    if type == typeFilter then res[#res+1] = key end
  end
  return res
end

function RedisEmbeddedContext:fromRedisHash(keysOrKeyPattern, numPartitions)
  local allKeys = redis.call('KEYS', keysOrKeyPattern)
  local hashKeys = self:filterKeysByType(allKeys, 'hash')
  local res = {}
  for _, hashKey in ipairs(hashKeys) do
    local kvs = redis.call('HGETALL', hashKey)
    for i=2,#kvs,2 do
      local k, v = kvs[i-1], kvs[i]
      res[#res+1] = {k, v}
    end
  end
  return self:parallelize(res, numPartitions)
end

function RedisEmbeddedContext:fromRedisKV(keysOrKeyPattern, numPartitions)
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local allKeys = redis.call('KEYS', keysOrKeyPattern)
    local stringKeys = self:filterKeysByType(allKeys, 'string')
    local mgetRes = redis.call('MGET', unpack(stringKeys))
    local res = {}
    for i, stringKey in ipairs(stringKeys) do
      res[#res+1] = {stringKey, mgetRes[i]}
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisEmbeddedContext:fromRedisList(keysOrKeyPattern, numPartitions)
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local allKeys = redis.call('KEYS', keysOrKeyPattern)
    local listKeys = self:filterKeysByType(allKeys, 'list')
    local res = {}
    for _, listKey in ipairs(listKeys) do
      local values = redis.call('LRANGE', listKey, 0, -1)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisEmbeddedContext:fromRedisSet(keysOrKeyPattern, numPartitions)
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local allKeys = redis.call('KEYS', keysOrKeyPattern)
    local setKeys = self:filterKeysByType(allKeys, 'set')
    local res = {}
    for _, setKey in ipairs(setKeys) do
      local values = redis.call('SMEMBERS', setKey)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisEmbeddedContext:fromRedisZRange(keysOrKeyPattern, startRange, endRange, numPartitions)
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local allKeys = redis.call('KEYS', keysOrKeyPattern)
    local zsetKeys = self:filterKeysByType(allKeys, 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local values = redis.call('ZRANGE', zsetKey, startRange, endRange)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisEmbeddedContext:fromRedisZRangeByScore(keysOrKeyPattern, startScore, endScore, numPartitions)
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local allKeys = redis.call('KEYS', keysOrKeyPattern)
    local zsetKeys = self:filterKeysByType(allKeys, 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local values = redis.call('ZRANGEBYSCORE', zsetKey, startScore, endScore)
      for _, value in ipairs(values) do
        res[#res+1] = value
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisEmbeddedContext:fromRedisZRangeWithScore(keysOrKeyPattern, startRange, endRange, numPartitions)
  if type(keysOrKeyPattern) == 'table' then
    error('NIY')
  else
    local allKeys = redis.call('KEYS', keysOrKeyPattern)
    local zsetKeys = self:filterKeysByType(allKeys, 'zset')
    local res = {}
    for _, zsetKey in ipairs(zsetKeys) do
      local kvs = redis.call('ZRANGE', zsetKey, startRange, endRange, 'WITHSCORES')
      for i=2,#kvs,2 do
        local k, v = kvs[i-1], tonumber(kvs[i])
        res[#res+1] = {k, v}
      end
    end
    return self:parallelize(res, numPartitions)
  end
end

function RedisEmbeddedContext:fromRedisZSet(keysOrKeyPattern, numPartitions)
  return self:fromRedisZRange(keysOrKeyPattern, 0, -1, numPartitions)
end

function RedisEmbeddedContext:fromRedisZSetWithScore(keysOrKeyPattern, numPartitions)
  return self:fromRedisZRangeWithScore(keysOrKeyPattern, 0, -1, numPartitions)
end

function RedisEmbeddedContext:setHash(hashName, data, ttl)
  for _, kv in ipairs(data) do
    local k,v = kv[1], kv[2]
    redis.call('HSET', hashName, k, v)
    if ttl and ttl > 0 then
      redis.call('EXPIRE', hashName, ttl)
    end
  end
end

function RedisEmbeddedContext:setKVs(data, ttl)
  for _, kv in ipairs(data) do
    local k,v = kv[1], kv[2]
    if ttl and ttl > 0 then
      redis.call('SETEX', k, ttl, v)
    else
      redis.call('SET', k, v)
    end
  end
end

function RedisEmbeddedContext:setList(listName, data, ttl)
  for _, v in ipairs(data) do
    redis.call('RPUSH', listName, v)
    if ttl and ttl > 0 then
      redis.call('EXPIRE', listName, ttl)
    end
  end
end

function RedisEmbeddedContext:setSet(setName, data, ttl)
  for _, v in ipairs(data) do
    redis.call('SADD', setName, v)
    if ttl and ttl > 0 then
      redis.call('EXPIRE', setName, ttl)
    end
  end
end

function RedisEmbeddedContext:setZset(zsetName, data, ttl)
  for _, kv in ipairs(data) do
    local k,v = kv[1], tonumber(kv[2])
    redis.call('ZADD', zsetName, v, k)
    if ttl and ttl > 0 then
      redis.call('EXPIRE', zsetName, ttl)
    end
  end
end

function RedisEmbeddedContext:toRedisHASH(keyValuesRDD, hashName, ttl)
  keyValuesRDD:foreachPartition(function(data)
    self:setHash(hashName, data, ttl)
  end)
end

function RedisEmbeddedContext:toRedisKV(keyValuesRDD, ttl)
  keyValuesRDD:foreachPartition(function(data)
    self:setKVs(data, ttl)
  end)
end

function RedisEmbeddedContext:toRedisLIST(valuesRDD, listName, ttl)
  valuesRDD:foreachPartition(function(data)
    self:setList(listName, data, ttl)
  end)
end

function RedisEmbeddedContext:toRedisSET(valuesRDD, setName, ttl)
  valuesRDD:foreachPartition(function(data)
    self:setSet(setName, data, ttl)
  end)
end

function RedisEmbeddedContext:toRedisZSET(valuesRDD, setName, ttl)
  valuesRDD:foreachPartition(function(data)
    self:setZset(setName, data, ttl)
  end)
end

return RedisEmbeddedContext
