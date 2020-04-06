local constants = require "kong.constants"
local cjson = require "cjson.safe"
local redis = require "resty.redis"
local ck = require "resty.cookie"


local kong = kong
local type = type


local _realm = 'Key realm="' .. _KONG._NAME .. '"'


local RedisAuthHandler = {}


RedisAuthHandler.PRIORITY = 1003
RedisAuthHandler.VERSION = "0.1.0"


local function load_consumer(redis_host, redis_port, key)
  local red = redis:new()
  local ok_con, err_con = red:connect(redis_host, redis_port)

  if not ok_con then
    kong.log("failed to connect redis", err_con)  
    return nil, { status = 401, message = "failed to connect redis" }
  end

  local result, err = red:get(key)
  if not result then
    kong.log("failed to get key: ", err)  
    return nil, { status = 401, message = "failed to get key" }
  end

  if result == ngx.null then
    return nil, { status = 401, message = "not found key" }
  end

  local ok_pool, err_pool = red:set_keepalive(10000, 100)
  if not ok_pool then
    kong.log("failed to set keepalive: ", err_pool)  
    return nil, { status = 401, message = "failed to set keepalive" }
  end

  return result  
end


local function set_consumer(consumer, consumer_keys)
  local set_header = kong.service.request.set_header
  local clear_header = kong.service.request.clear_header
  
  for i,v in ipairs(consumer_keys) do
    if consumer and consumer[v] then
      set_header('X-Consumer-'..v, consumer[v])
    else
      clear_header('X-Consumer-'..v)
    end
  end
end


local function do_authentication(conf)
  if type(conf.key_names) ~= "table" then
    kong.log.err("no conf.key_names set, aborting plugin execution")
    return nil, { status = 500, message = "Invalid plugin configuration" }
  end

  local headers = kong.request.get_headers()
  local query = kong.request.get_query()
  local cookies = ck:new()
  local key
  local body

  -- read in the body if we want to examine POST args
  if conf.key_in_body then
    local err
    body, err = kong.request.get_body()

    if err then
      kong.log.err("Cannot process request body: ", err)
      return nil, { status = 400, message = "Cannot process request body" }
    end
  end

  -- search in headers & querystring
  for i = 1, #conf.key_names do
    local name = conf.key_names[i]
    local v = headers[name]
    if not v then
      -- search in querystring
      v = query[name]
    end

    -- search in cookie
    if not v then
      v = cookies:get(name)
    end

    -- search the body, if we asked to
    if not v and conf.key_in_body then
      v = body[name]
    end

    if type(v) == "string" then
      key = v

      if conf.hide_credentials then
        query[name] = nil
        kong.service.request.set_query(query)
        kong.service.request.clear_header(name)

        if conf.key_in_body then
          body[name] = nil
          kong.service.request.set_body(body)
        end
      end

      break

    elseif type(v) == "table" then
      -- duplicate API key
      return nil, { status = 401, message = "Duplicate API key found" }
    end
  end

  -- this request is missing an API key, HTTP 401
  if not key or key == "" then
    kong.response.set_header("WWW-Authenticate", _realm)
    return nil, { status = 401, message = "No API key found in request" }
  end

  local consumer, err = load_consumer(conf.redis_host,conf.redis_port,conf.redis_key_prefix .. key)
  if not consumer then
    return nil, { status = 401, message = "API key error" }
  end

  set_consumer(cjson.decode(consumer),conf.consumer_keys)

  return true
end


function RedisAuthHandler:access(conf)
  
  -- check if preflight request and whether it should be authenticated
  if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
    return
  end

  if conf.anonymous then
    -- we're already authenticated, and we're configured for using anonymous,
    -- hence we're in a logical OR between auth methods and we're already done.
    return
  end

  local ok, err = do_authentication(conf)
  if not ok then
    return kong.response.exit(err.status, { message = err.message }, err.headers)
  end
end


return RedisAuthHandler
