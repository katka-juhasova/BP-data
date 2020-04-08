local singletons = require "kong.singletons"
local timestamp = require "kong.tools.timestamp"
local redis = require "resty.redis"
local reports = require "kong.reports"
local ngx_log = ngx.log

local pairs = pairs
local fmt = string.format

local get_local_key = function(route_id, identifier, period_date, name)
  return fmt("ratelimit:%s:%s:%s:%s", route_id, identifier, period_date, name)
end

local EXPIRATIONS = {
  second = 1,
  minute = 60,
  hour = 3600,
  day = 86400,
  month = 2592000,
  year = 31536000
}

return {
  increment = function(conf, limits, route_id, identifier, current_timestamp, value)
    local red = redis:new()
    red:set_timeout(conf.redis_timeout)
    local ok, err = red:connect(conf.redis_host, conf.redis_port)
    if not ok then
      ngx_log(ngx.ERR, "failed to connect to Redis: ", err)
      return nil, err
    end

    if conf.redis_password and conf.redis_password ~= "" then
      local ok, err = red:auth(conf.redis_password)
      if not ok then
        ngx_log(ngx.ERR, "failed to connect to Redis: ", err)
        return nil, err
      end
    end

    if conf.redis_database ~= nil and conf.redis_database > 0 then
      local ok, err = red:select(conf.redis_database)
      if not ok then
        ngx_log(ngx.ERR, "failed to change Redis database: ", err)
        return nil, err
      end
    end

    local keys = {}
    local expirations = {}
    local idx = 0
    local periods = timestamp.get_timestamps(current_timestamp)
    for period, period_date in pairs(periods) do
      if limits[period] then
        local cache_key = get_local_key(route_id, identifier, period_date, period)
        local exists, err = red:exists(cache_key)
        if err then
          ngx_log(ngx.ERR, "failed to query Redis: ", err)
          return nil, err
        end

        idx = idx + 1
        keys[idx] = cache_key
        if not exists or exists == 0 then
          expirations[idx] = EXPIRATIONS[period]
        end
      end
    end

    red:init_pipeline()
    for i = 1, idx do
      red:incrby(keys[i], value)
      if expirations[i] then
        red:expire(keys[i], expirations[i])
      end
    end

    local _, err = red:commit_pipeline()
    if err then
      ngx_log(ngx.ERR, "failed to commit pipeline in Redis: ", err)
      return nil, err
    end
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
      ngx_log(ngx.ERR, "failed to set Redis keepalive: ", err)
      return nil, err
    end

    return true
  end,
  usage = function(conf, route_id, identifier, current_timestamp, name)
    local red = redis:new()
    red:set_timeout(conf.redis_timeout)
    local ok, err = red:connect(conf.redis_host, conf.redis_port)
    if not ok then
      ngx_log(ngx.ERR, "failed to connect to Redis: ", err)
      return nil, err
    end

    if conf.redis_password and conf.redis_password ~= "" then
      local ok, err = red:auth(conf.redis_password)
      if not ok then
        ngx_log(ngx.ERR, "failed to connect to Redis: ", err)
        return nil, err
      end
    end

    if conf.redis_database ~= nil and conf.redis_database > 0 then
      local ok, err = red:select(conf.redis_database)
      if not ok then
        ngx_log(ngx.ERR, "failed to change Redis database: ", err)
        return nil, err
      end
    end

    reports.retrieve_redis_version(red)

    local periods = timestamp.get_timestamps(current_timestamp)
    local cache_key = get_local_key(route_id, identifier, periods[name], name)
    local current_metric, err = red:get(cache_key)
    if err then
      return nil, err
    end

    if current_metric == ngx.null then
      current_metric = nil
    end

    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
      ngx_log(ngx.ERR, "failed to set Redis keepalive: ", err)
    end

    return current_metric or 0
  end
}
