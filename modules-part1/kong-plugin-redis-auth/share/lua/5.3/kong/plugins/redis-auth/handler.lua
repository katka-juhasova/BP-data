local constants = require "kong.constants"
local cjson = require "cjson.safe"
local redis = require "resty.redis"
local ck = require "resty.cookie"


local kong = kong
local type = type


local _realm = 'Key realm="' .. _KONG._NAME .. '"'


local RedisAuthHandler = {}


RedisAuthHandler.PRIORITY = 1003
RedisAuthHandler.VERSION = "0.1.3"

local function load_redis(conf)
  local red = redis:new()
  local ok, err = red:connect(conf.redis_host, conf.redis_port)

  if err then
    return nil, err
  end

  if conf.redis_password and conf.redis_password ~= "" then
    local ok, err = red:auth(conf.redis_password)
    if err then
      return nil, err
    end
  end
  
  return red

end

local function load_consumer(conf, key)
  local red, err = load_redis(conf)

  if err then
    kong.log("failed to connect redis", err)
    return nil, err
  end

  local value, err = red:get(conf.redis_key_prefix .. key)
  if err then
    kong.log("failed to get key: ", err)  
    return nil, err
  end

  red:set_keepalive(conf.redis_timeout, conf.redis_pool)
  
  if value == ngx.null then
    return nil, { status = 401, message = "not found key" }
  end

  return value

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

  local consumer, err = load_consumer(conf, key)
  if err then
    return nil, err
  end

  set_consumer(cjson.decode(consumer),conf.consumer_keys)

  return true
end


function RedisAuthHandler:access(conf)
  
  -- check if preflight request and whether it should be authenticated
  if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
    return
  end

  if conf.anonymous and kong.client.get_credential() then
    -- we're already authenticated, and we're configured for using anonymous,
    -- hence we're in a logical OR between auth methods and we're already done.
    return
  end

  local ok, err = do_authentication(conf)
  if not ok then
    if conf.anonymous then
      local request_path = kong.request.get_path()..'/'
      for i, v in ipairs(conf.anonymous_paths) do
        local match_path = v..'/'
        if string.sub(request_path,1,string.len(match_path)) == match_path then
          -- get anonymous user
          set_consumer(cjson.decode(conf.anonymous_consumer), conf.consumer_keys)
          return
        end
      end
    end
    return kong.response.exit(err.status, { message = err.message }, err.headers)
  end
end


return RedisAuthHandler
