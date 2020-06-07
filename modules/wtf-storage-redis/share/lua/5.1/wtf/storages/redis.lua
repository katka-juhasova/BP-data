local require = require
local tools = require("wtf.core.tools")
local Storage = require("wtf.core.classes.storage")


local _M = Storage:extend()
_M.name = "redis"

function _M:init(...)
  local err = tools.error
  local ok, e, conn
  
  local name = self:get_optional_parameter('name') or self.name
  local connection_method = self:get_mandatory_parameter('connection_method')

  if connection_method == "tcp" then
    local redis = require("wtf.fork.resty.redis.tcp")
    local host = self:get_optional_parameter('host') or "127.0.0.1"
    local port = self:get_optional_parameter('port') or "6379"
    
    conn = redis:new()
    ok, e = conn:connect(host, port)
  elseif connection_method == "unix" then
    local redis = require("wtf.fork.resty.redis.unix")
    local redis_socket = self:get_mandatory_parameter('socket')
    
    conn = redis:new()
    ok, e = conn:connect(redis_socket)
  else
    err("Unsupported connection method: '"..connection_method.."'. Supported methods are: 'tcp', 'unix'")
  end

  self.handler = {}

  if ok ~= nil then
    self.handler = conn
    conn:set_timeout(1000)
  else
    err("Error when connecting to storage '"..name.."': "..e)
  end

  return self
end

function _M:get(key)
  local err = tools.error
  local name = self:get_optional_parameter('name') or self.name
  local search_condition = {}
  local doc = {}
  local e

  if self.handler == nil then err("Handler is nil when getting data from storage '"..name.."'") end

  if key ~= nil then
    doc, e = self.handler:get(key)
  else
    err("Cannot get value for empty key from storage '"..name.."'")
  end

  if doc ~= nil then
    return doc
  else
    return nil
  end
end

function _M:set(key, value)
  local err = tools.error
  local name = self:get_optional_parameter('name') or self.name
  local search_condition = {}
  local new_data = {}
  local num, e

  if self.handler == nil then err("Handler is nil when getting data from storage '"..name.."'") end

  if key ~= nil then
    if value == nil then value = "" end
    local ok,err = self.handler:set(key,value)
    if err ~= nil then
      err("Key-value set error for storage '"..name.."'")
    end
  else
    err("Cannot set value for empty key from storage '"..name.."'")
  end

  return self
end

function _M:del(key)
  local err = tools.error
  local name = self:get_optional_parameter('name') or self.name
  local search_condition = {}
  local num, e

  if self.handler == nil then err("Handler is nil when deleting data from storage '"..name.."'") end

  if key ~= nil then
    num, e = self.handler:del(key) 
    if e ~= nil then
      err("Cannot delete value for empty key from storage '"..name.."'")
    end
  else
    err("Cannot delete value for empty key from storage '"..name.."'")
  end

  return self
end

return _M
