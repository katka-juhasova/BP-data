local BasePlugin = require "kong.plugins.base_plugin"

local ApiKeyAccessControlHandler = BasePlugin:extend()

ApiKeyAccessControlHandler.PRIORITY = 950

local function compose_rule_from_context(api_key)
  local method = kong.request.get_method()
  local path = kong.request.get_path()
  local query = kong.request.get_raw_query()
  local uri = query ~= "" and table.concat({path, query}, "?") or path
  return table.concat({api_key, method, uri}, " ")
end

local function is_key_in_list_of_keys(key, list_of_keys)
  for i = 1, #list_of_keys do
    if list_of_keys[i] == key then
      return true
    end
  end
  return false
end

local function is_rule_in_whitelist(rule, whitelist)
  for i = 1, #whitelist do
    if whitelist[i] == rule then
      return true
    end
  end
  return false
end

function ApiKeyAccessControlHandler:new()
  ApiKeyAccessControlHandler.super.new(self, "api-key-access-control")
end

function ApiKeyAccessControlHandler:access(config)
  ApiKeyAccessControlHandler.super.access(self)

  local api_key = kong.request.get_header("x_credential_username")
  local rule = compose_rule_from_context(api_key)

  if is_key_in_list_of_keys(api_key, config.api_keys) then
    if is_rule_in_whitelist(rule, config.whitelist) then
      return
    end
    return kong.response.exit(403)
  end

  return
end

return ApiKeyAccessControlHandler
