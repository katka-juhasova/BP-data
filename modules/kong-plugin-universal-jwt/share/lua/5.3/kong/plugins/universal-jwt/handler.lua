local singletons = require "kong.singletons"
local table_insert = table.insert
local jwt = require "luajwtjitsi"
local constants = require "kong.constants"
local env = require '/kong/plugins/universal-jwt/env' -- relative paths don't work for some reason ???

-- load the base plugin object and create a subclass
local BasePlugin = require "kong.plugins.base_plugin"
local UniversalJwtHandler = BasePlugin:extend()

local function fetch_acls(consumer_id)
  local acls_for_consumer = {}
  for row, err in kong.db.acls:each_for_consumer({id = consumer_id}) do
    if err then
      return nil, err
    end
    table.insert(acls_for_consumer, row)
  end
  return acls_for_consumer
end

local function add_jwt()
  local consumer
  if ngx.ctx.authenticated_consumer then
    consumer = ngx.ctx.authenticated_consumer
  else
    return responses.send_HTTP_FORBIDDEN("Cannot identify the consumer")
  end

  local acls, err = fetch_acls(consumer.id)
  if err then
    ngx.log(ngx.ERR, err)
    return responses.send_HTTP_INTERNAL_SERVER_ERROR()
  end
  if not acls then acls = {} end

  -- Strip everything out apart from group
  local roles = {}
  for _, v in ipairs(acls) do
    table_insert(roles, v.group)
  end

  local payload = {
    iss = consumer.username,
    scopes = {
      roles = roles
    },
    exp = ngx.time() + 100 -- short lived JWT as will be created for every request
  }
  local jwt_token, err = jwt.encode(payload, env.jwt_private_key, "RS256")
  if err then
    ngx.log(ngx.ERR, err)
    return responses.send_HTTP_INTERNAL_SERVER_ERROR()
  end
  ngx.log(ngx.INFO, "key auth plugin found, adding jwt for consumer " .. consumer.username)
  if (ngx.req.get_headers()["x-localz-deviceid"]) then
    ngx.log(ngx.INFO, "x-localz-deviceid: " .. ngx.req.get_headers()["x-localz-deviceid"])
  end
  ngx.req.set_header("Authorization", "Bearer " .. jwt_token)

end

-- constructor
function UniversalJwtHandler:new()
  UniversalJwtHandler.super.new(self, "universal-jwt")
  -- do initialization here, runs in the 'init_by_lua_block', before worker processes are forked
end

---[[ runs in the 'access_by_lua_block'
function UniversalJwtHandler:access(plugin_conf)
  UniversalJwtHandler.super.access(self)
  if (ngx.ctx.plugins ~= nil and ngx.ctx.plugins["key-auth"] ~= nil) then
    add_jwt()
  end
end --]]

-- set the plugin priority, which determines plugin execution order
UniversalJwtHandler.PRIORITY = 500

-- return our plugin object
return UniversalJwtHandler
