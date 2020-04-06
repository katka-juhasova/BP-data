-- Copyright (C) UPYUN Inc.

local BasePlugin = require "kong.plugins.base_plugin"
local singletons = require "kong.singletons"
local constants = require "kong.constants"
local responses = require "kong.tools.responses"

local ngx_set_header = ngx.req.set_header
local ngx_get_headers = ngx.req.get_headers

local ForwardedUserAuthHandler = BasePlugin:extend()

local function load_consumer_into_memory(consumer_id, anonymous)
  local result, err = singletons.db.consumers:select { id = consumer_id }
  if not result then
    if anonymous and not err then
      err = 'anonymous consumer "' .. consumer_id .. '" not found'
    end
    return nil, err
  end
  return result
end

local function set_consumer(consumer, credential)
  ngx_set_header(constants.HEADERS.CONSUMER_ID, consumer.id)
  ngx_set_header(constants.HEADERS.CONSUMER_CUSTOM_ID, consumer.custom_id)
  ngx_set_header(constants.HEADERS.CONSUMER_USERNAME, consumer.username)
  ngx.ctx.authenticated_consumer = consumer

  if credential then
    ngx_set_header(constants.HEADERS.CREDENTIAL_USERNAME, credential.username)
    ngx.ctx.authenticated_credential = credential
    ngx_set_header(constants.HEADERS.ANONYMOUS, nil) -- in case of auth plugins concatenation
  else
    ngx_set_header(constants.HEADERS.ANONYMOUS, true)
  end
end

local function do_authentication(conf)
  local headers = ngx_get_headers()
  local username = headers["X-Forwarded-User"]
  if not username then
    return nil, { status = 401, message = "Forwarded user auth header not found" }
  end

  local consumer, err = singletons.db.consumers:select_by_username(username)
  if not consumer then
    return nil, { status = 401, message = "Forwarded user '" .. username .. "' not found" }
  end

  set_consumer(consumer, {})

  return true
end

function ForwardedUserAuthHandler:new()
  ForwardedUserAuthHandler.super.new(self, "forward-user-auth")
end

function ForwardedUserAuthHandler:access(conf)
  ForwardedUserAuthHandler.super.access(self)

  if ngx.ctx.authenticated_credential and conf.anonymous ~= "" then
    -- we're already authenticated, and we're configured for using anonymous,
    -- hence we're in a logical OR between auth methods and we're already done.
    return
  end

  local ok, err = do_authentication(conf)
  if not ok then
    if conf.anonymous ~= "" then
      -- get anonymous user
      local consumer_cache_key = singletons.db.consumers:cache_key(conf.anonymous)
      local consumer, err      = singletons.cache:get(consumer_cache_key, nil,
                                                      load_consumer_into_memory,
                                                      conf.anonymous, true)
      if err then
        return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
      end
      set_consumer(consumer, nil)
    else
      return responses.send(err.status, err.message)
    end
  end
end

ForwardedUserAuthHandler.PRIORITY = 1100
ForwardedUserAuthHandler.VERSION = "0.1.0"

return ForwardedUserAuthHandler