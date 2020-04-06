----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

--- Request factory
local Request = require "lugate.request"

--- HTTP Statuses
local HttpStatuses = require 'lugate.http_statuses'

--- The lua gateway class definition
local Lugate = {
  ERR_PARSE_ERROR = -32700, -- Error code for "Parse error" error
  ERR_INVALID_REQUEST = -32600, -- Error code for "Invalid request" error
  ERR_METHOD_NOT_FOUND = -32601, -- Error code for "Method not found" error
  ERR_INVALID_PARAMS = -32602, -- Error code for "Invalid params" error
  ERR_INTERNAL_ERROR = -32603, -- Error code for "Internal error" error
  ERR_SERVER_ERROR = -32000, -- Error code for "Server error" error
  ERR_INVALID_PROXY_CALL = -32098, -- Error code for "Invalid proxy call" error
  ERR_EMPTY_REQUEST = -32097, -- Error code for "Empty request" error
  VERSION = '0.6.1', -- Current version
  DBG_MSG = 'DBG %s>>%s<<', -- Template for error log
  REQ_PREF = 'REQ', -- Request prefix (used in log message)
  RESP_PREF = 'RESP', -- Response prefix (used in log message)
}

Lugate.HTTP_POST = 8

--- Create new Lugate instance
-- @param[type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return[type=table] The new instance of Lugate
function Lugate:new(config)
  config.hooks = config.hooks or {}
  config.hooks.pre = config.hooks.pre or function() end
  config.hooks.post = config.hooks.post or function() end
  config.hooks.cache = config.hooks.cache or function() end
  config.debug = config.debug or false

  assert(type(config.ngx) == "table", "Parameter 'ngx' is required and should be a table!")
  assert(type(config.json) == "table", "Parameter 'json' is required and should be a table!")
  assert(type(config.hooks.pre) == "function", "Parameter 'pre' is required and should be a function!")
  assert(type(config.hooks.post) == "function", "Parameter 'post' is required and should be a function!")
  assert(type(config.hooks.cache) == "function", "Parameter 'cache' is required and should be a function!")
  assert(type(config.debug) == "boolean", "Parameter 'debug' is required and should be a function!")

  -- Define metatable
  local lugate = setmetatable({}, Lugate)
  self.__index = self

  -- Define services and configs
  config.cache = config.cache or {'dummy'}
  local cache = lugate:load_module(config.cache, { dummy = "lugate.cache.dummy", redis = "lugate.cache.redis" })

  lugate.hooks = config.hooks
  lugate.ngx = config.ngx
  lugate.json = config.json
  lugate.routes = config.routes or {}
  lugate.cache = cache
  lugate.req_dat = { num = {}, key = {}, ttl = {}, tags = {}, ids = {} }
  lugate.responses = {}
  lugate.debug = config.debug

  return lugate
end

--- Load module from the list of alternatives
-- @return[type=table] Loaded module
function Lugate:load_module(definition, alternatives)
  local name = table.remove(definition, 1)
  assert(type(name) == "string", "Parameter 'name' is required and should be a string!")
  assert(type(alternatives) == "table", "Parameter 'alternatives' is required and should be a table!")
    local aliases = ''
    for alias, module in pairs(alternatives) do
      if alias == name then
        local class = require(module)
        return class:new(unpack(definition))
      end
      aliases = '' == aliases and alias or aliases .. "', '" .. alias
    end

    error("Unknown module '" .. name .. "'. Available modules are: '" .. aliases .. "'")
end

--- Create new Lugate instance. Initialize ngx dependent properties
-- @param[type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return[type=table] The new instance of Lugate
function Lugate:init(config)
  -- Create new lugate instance
  local lugate = self:new(config)

  -- Print version to header
  lugate.ngx.header["X-Lugate-Version"] = Lugate.VERSION;

  -- Check request method
  if 'POST' ~= lugate.ngx.req.get_method() then
    lugate.ngx.say(lugate:build_json_error(Lugate.ERR_INVALID_REQUEST, 'Only POST requests are allowed'))
    lugate.ngx.exit(lugate.ngx.HTTP_OK)
  end

  -- Build config
  lugate.ngx.req.read_body() -- explicitly read the req body

  if not lugate:is_not_empty() then
    lugate.ngx.say(lugate:build_json_error(Lugate.ERR_EMPTY_REQUEST))
    lugate.ngx.exit(lugate.ngx.HTTP_OK)
  end

  return lugate
end

--- Format error message
-- @param[type=string] message Log text
-- @param[type=string] comment Log note
-- @return[type=string]
function Lugate:write_log(message, comment)
  if self.debug then
      comment = comment and '(' .. comment .. ')' or ''
      self.ngx.log(self.ngx.ERR, string.format(Lugate.DBG_MSG, comment, message))
  end
end

--- Get a proper formated json error
-- @param[type=int] code Error code
-- @param[type=string] message Error message
-- @param[type=table] data Additional error data
-- @param[type=number] id Request id
-- @return[type=string]
function Lugate:build_json_error(code, message, data, id)
  local messages = {
    [Lugate.ERR_PARSE_ERROR] = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
    [Lugate.ERR_INVALID_REQUEST] = 'The JSON sent is not a valid Request object.',
    [Lugate.ERR_METHOD_NOT_FOUND] = 'The method does not exist / is not available.',
    [Lugate.ERR_INVALID_PARAMS] = 'Invalid method parameter(s).',
    [Lugate.ERR_INTERNAL_ERROR] = 'Internal JSON-RPC error.',
    [Lugate.ERR_SERVER_ERROR] = 'Server error',
    [Lugate.ERR_EMPTY_REQUEST] = 'Empty request.',
    [Lugate.ERR_INVALID_PROXY_CALL] = 'Invalid proxy call.',
  }
--  local code = messages[code] and code or Lugate.ERR_SERVER_ERROR
  local code = (messages[code] or HttpStatuses[code]) and code or Lugate.ERR_SERVER_ERROR
  local message = message or messages[code]
  local data = data and self.json.encode(data) or 'null'
  local id = id or 'null'

  return '{"jsonrpc":"2.0","error":{"code":' .. tostring(code) .. ',"message":"' .. message .. '","data":' .. data .. '},"id":' .. id .. '}'
end

--- Check if request is empty
-- @return[type=boolean]
function Lugate:is_not_empty()
  return self:get_body() ~= '' and true or false
end

--- Get ngx request body
-- @return[type=string]
function Lugate:get_body()
  if not self.body then
    self.body = self.ngx.req and self.ngx.req.get_body_data() or ''
  end

  return self.body
end

--- Parse raw body
-- @return[type=table]
function Lugate:get_data()
  if not self.data then
    self.data = self:get_body() and self.json.decode(self.body) or {}
  end

  return self.data
end

--- Check if request is a batch
-- @return[type=boolean]
function Lugate:is_batch()
  if not self.batch then
    local data = self:get_data()
    self.batch =  data and data[1] and ('table' == type(data[1])) and true or false
  end

  return self.batch
end

--- Get request collection
-- @return[type=table] The table of requests
function Lugate:get_requests()
  if not self.requests then
    self.requests = {}
    local data = self:get_data()
    if self:is_batch() then
      for _, rdata in ipairs(data) do
        table.insert(self.requests, Request:new(rdata, self))
      end
    else
      table.insert(self.requests, Request:new(data, self))
    end
  end

  return self.requests
end

--- Get request collection prepared for ngx.location.capture_multi call
-- @return[type=table] The table of requests
function Lugate:run()
  -- Execute 'pre' middleware
  if false == self.hooks:pre() then
    return ngx.exit(ngx.HTTP_OK)
  end

  -- Loop requests
  local ngx_requests = {}
  for i, request in ipairs(self:get_requests()) do
    self:attach_request(i, request, ngx_requests)
  end

  -- Send multi requst and get multi response
  if #ngx_requests > 0 then
    local responses = { self.ngx.location.capture_multi(ngx_requests) }
    for n, response in ipairs(responses) do
      self:handle_response(n, response)
    end
  end

  -- Execute 'post' middleware
  if false == self.hooks:post() then
    return ngx.exit(ngx.HTTP_OK)
  end

  return self.responses
end

--- Attach request to the pipeline
-- @param[type=number] i Requets key
-- @param[type=table] request Request object
-- @param[type=table] ngx_requests Table of nginx requests
-- @return[type=boolean]
function Lugate:attach_request(i, request, ngx_requests)
  self:write_log(request:get_body(), Lugate.REQ_PREF)

  if request:is_cachable() and self.cache:get(request:get_key()) then
    self.responses[i] = self.cache:get(request:get_key())
  elseif request:is_proxy_call() then
    local req, err = request:get_ngx_request()
    if req then
      table.insert(ngx_requests, req)
      local req_count = #ngx_requests

      self.req_dat.num[req_count] = i
      self.req_dat.key[req_count] = request:get_key()
      self.req_dat.ttl[req_count] = request:get_ttl()
      self.req_dat.tags[req_count] = request:get_tags()
      self.req_dat.ids[req_count] = request:get_id()
    else
      self.responses[i] = self:clean_response(self:build_json_error(Lugate.ERR_SERVER_ERROR, err, request:get_body(), request:get_id()))
    end
  elseif not request:is_proxy_call() then
    self.responses[i] = self:clean_response(self:build_json_error(Lugate.ERR_INVALID_PROXY_CALL, nil, request:get_body(), request:get_id()))
  else
    self.responses[i] = self:clean_response(self:build_json_error(Lugate.ERR_PARSE_ERROR, nil, request:get_body(), request:get_id()))
  end

  return true
end

--- Handle every single response
-- @param[type=number] n Response number
-- @param[type=table] response Response object
-- @return[type=boolean]
function Lugate:handle_response(n, response)
  -- HTTP code <> 200
  if self.ngx.HTTP_OK ~= response.status then
    local response_msg = HttpStatuses[response.status] or 'Unknown error'
    local data = self.ngx.HTTP_INTERNAL_SERVER_ERROR == response.status and self:clean_response(response.body) or nil
    self.responses[self.req_dat.num[n]] = self:build_json_error(
      response.status, response_msg, data, self.req_dat.ids[n]
    )

  -- HTTP code == 200
  else
    self.responses[self.req_dat.num[n]] = self:clean_response(response)

    -- Quick way to find invalid responses
    local first_char = string.sub(self.responses[self.req_dat.num[n]], 1, 1);
    local last_char = string.sub(self.responses[self.req_dat.num[n]], -1);
    local broken = false

    -- JSON check
    if ('' == self.responses[self.req_dat.num[n]]) or ('{' ~= first_char and '[' ~= first_char) or ('}' ~= last_char and ']' ~= last_char) then
      -- Process empty or broken responses
      self.responses[self.req_dat.num[n]] = self:clean_response(self:build_json_error(
        Lugate.ERR_SERVER_ERROR, 'Server error. Bad JSON-RPC response.', nil, self.req_dat.ids[n]
      ))
      broken = true
    end

    -- Store to cache
    if not broken and self.req_dat.key[n] and false ~= self.hooks:cache(response) and not self.cache:get(self.req_dat.key[n]) then
      self.cache:set(self.req_dat.key[n], self.responses[self.req_dat.num[n]], self.req_dat.ttl[n])
      -- Store keys to tag sets
      if self.req_dat.tags[n] then
        for _, tag in ipairs(self.req_dat.tags[n]) do
          self.cache:sadd(tag, self.req_dat.key[n])
        end
      end
    end
  end

  -- Push to log
  self:write_log(self.responses[self.req_dat.num[n]], Lugate.RESP_PREF)

  return true
end

--- Clean response (trim)
function Lugate:clean_response(response)
  local response_body = response.body or response
  return response_body:match'^()%s*$' and '' or response_body:match'^%s*(.*%S)'
end

--- Get responses as a string
-- @return[type=string]
function Lugate:get_result()
  if false == self:is_batch() then
    return self.responses[1]
  end

  return '[' .. table.concat(self.responses, ",") .. ']'
end

--- Print all responses and exit
function Lugate:print_responses()
  ngx.say(self:get_result())

  ngx.exit(ngx.HTTP_OK)
end

return Lugate