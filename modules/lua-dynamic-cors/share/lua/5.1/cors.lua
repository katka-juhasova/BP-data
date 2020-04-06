local redis = require 'resty.redis'
local rc = require "resty.redis.connector"

local split = function(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end


local DEFAULT_TTL = 10 -- in seconds

local cors = { opts = {} }
cors.init = function(opts)
  if type(opts) ~= 'table' then
    return nil, 'opts must be a table'
  end

  if type(opts.dict_name) ~= 'string' then
    return nil, 'dict_name must be a string'
  elseif not ngx.shared[opts.dict_name] then
    return nil, 'no shared dict '..opts.dict_name
  end

  cors.cache = ngx.shared[opts.dict_name]

  cors.opts['dict_name'] = opts.dict_name

  if type(opts.redis) ~= 'table' then
    return nil, 'redis opts must be a table'
  end

  cors.redis_opts = {
    master_name = opts.redis.master_name,
    password = opts.redis.password,
    connect_timeout = 1000,
    sentinels = {},
  }

  local hosts = split(opts.redis.hosts, ",")
  for i, h in ipairs(hosts) do
    cors.redis_opts['sentinels'][i] = { host = h, port = opts.redis.port }
  end

  cors.opts['ttl'] = opts.ttl or DEFAULT_TTL
  cors.opts['default_domain'] = opts.default_domain
end

cors.set_header = function(host)
  local allowed_domain = cors.cache:get(host)
  if allowed_domain ~= nil then
    ngx.header["Access-Control-Allow-Origin"] = allowed_domain
    return
  end

  local red, err = rc.new(cors.redis_opts):connect()
  if not red then
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    ngx.header["Access-Control-Allow-Origin"] = host
    return
  end

  local allowed_domain = cors.opts.default_domain -- default domain

  local is_member, err = red:sismember(cors.opts.dict_name, host)
  if not is_member then
    ngx.log(ngx.ERR, "failed to check if " .. host.. "is allowed: ", err)
    ngx.header["Access-Control-Allow-Origin"] = host
    return
  end

  if is_member == 1 then -- checking whether host is member or not
    allowed_domain = host
  end

  cors.cache:set(host, allowed_domain, cors.opts.ttl)

  ngx.header["Access-Control-Allow-Origin"] = allowed_domain

  -- put it into the connection pool of size 100,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 100)
  if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    return
  end
end

return cors
