local json = require "cjson"
local http = require "resty.http"
local rstrip = require("pl.stringx").rstrip
local split = require("pl.stringx").split
local ck = require("resty.cookie")
local rate_limiting = require("kong.plugins.mithril.rate-limiting")
local uuid = require "kong.tools.utils".uuid

local kong = kong
local worker_uuid
local worker_counter

local MithrilHandler = {}
local req_headers = {}
local header_name = "x-request-id"

MithrilHandler.PRIORITY = 770
MithrilHandler.VERSION = "0.0.1"

local function get_correlation_id()
  local correlation_id = kong.request.get_header(header_name)
  if not correlation_id then
    -- Generate the header value
    local worker_pid = ngx.worker.pid()

    worker_counter = worker_counter + 1
    correlation_id = worker_uuid .. "#" .. worker_counter
  end

  return correlation_id
end

local function send_error(status_code, message)
  ngx.status = status_code
  ngx.header.content_type = "application/json"
  local type = "access_denied"
  if status_code == 403 then
    type = "forbidden"
  end

  local port = ""
  if ngx.var.server_port ~= 80 then
    port = ":" .. ngx.var.server_port
  end
  local error = {
    meta = {
      url = ngx.var.scheme .. "://" .. ngx.var.host .. port .. ngx.var.request_uri,
      type = "object",
      request_id = kong.ctx.plugin.correlation_id,
      code = status_code
    },
    error = {
      type = type,
      message = message
    }
  }
  ngx.say(json.encode(error))
end

local function validate_scopes(required_scopes, available_scopes)
  local missing_scopes = {}
  for k, required_scope in pairs(required_scopes) do
    local has_scope = false
    for key, consumer_scope in pairs(available_scopes) do
      if required_scope == consumer_scope then
        has_scope = true
        break
      end
    end
    if not has_scope then
      table.insert(missing_scopes, required_scope)
    end
  end

  return missing_scopes
end

local function find_rule(rules)
  local api_path = rstrip(ngx.ctx.router_matches.uri, "/")
  local request_path = ngx.var.uri

  local api_relative_path, n, err = ngx.re.gsub(request_path, api_path, "")
  local method = ngx.req.get_method()

  for k, rule in pairs(rules) do
    local path_matched, err = ngx.re.match(api_relative_path, "^" .. rule.path)

    method_matched = false
    for key, rule_method in pairs(rule.methods) do
      if rule_method == method then
        method_matched = true
        break
      end
    end
    if path_matched and method_matched then
      return rule
    end
  end
end

local function verify_url(url, error_msg)
  local api_key = ngx.req.get_headers()["api-key"]
  local httpc = http.new()
  local res, err =
    httpc:request_uri(
    url,
    {
      method = "GET",
      headers = {
        accept = "application/json",
        ["Content-Type"] = "application/json",
        ["api-key"] = api_key,
        ["x-request-id"] = kong.ctx.plugin.correlation_id
      }
    }
  )

  httpc:close()

  if not res or res.status ~= 200 then
    send_error(401, error_msg)
    return ngx.exit(200), true
  end
  return res
end

local function verify_details(body)
  local response = json.decode(body)
  local data = response.data or {}
  local urgent = response.urgent or {}
  local mis_client_id = urgent.mis_client_id
  local details = data.details or {}
  local broker_scope = details.broker_scope
  local user_id = data.user_id or data.consumer_id
  local scope = data.consumer_scope or details.scope
  local user = data.user or {}
  local person_id = user.person_id
  return mis_client_id, details, scope, broker_scope, user_id, person_id
end

function MithrilHandler:init_worker()
  worker_uuid = uuid()
  worker_counter = 0
end

local function set_mis_client_id(scope, mis_client_id, details)
  ngx.req.set_header("x-consumer-scope", scope)
  ngx.var.upstream_x_mis_client_id = mis_client_id
  if details.scope ~= nil then
    local x_consumer_metadata = json.encode(details)
    ngx.req.set_header("x-consumer-metadata", x_consumer_metadata)
    ngx.var.upstream_x_client_id = details.client_id
  end
end

local function check_scopes(rule, scope, broker_scope)
  if rule == nil then
    send_error(403, "ACL: No matching rule was found for path " .. ngx.ctx.router_matches.uri)
    return ngx.exit(200)
  end

  if scope == nil or scope == "" then
    send_error(
      403,
      "Your scope does not allow to access this resource. Missing allowances: " .. table.concat(rule.scopes, ", ")
    )
    return ngx.exit(200)
  end

  local missing_scopes = validate_scopes(rule.scopes, split(scope, " "))
  if #missing_scopes > 0 then
    send_error(
      403,
      "Your scope does not allow to access this resource. Missing allowances: " .. table.concat(missing_scopes, ", ")
    )
    return ngx.exit(200)
  end

  if broker_scope ~= nil then
    local missing_scopes = validate_scopes(rule.scopes, split(broker_scope, " "))
    if #missing_scopes > 0 then
      send_error(
        403,
        "Your scope does not allow to access this resource. Missing allowances: " .. table.concat(missing_scopes, ", ")
      )
      return ngx.exit(200)
    end
  end
end

local function check_abac(rule, user_id, mis_client_id, person_id, details)
  local abac = rule.abac
  if abac then
    local m, err = ngx.re.match(ngx.var.request_uri, abac.rule)
    local args, err = ngx.req.get_uri_args()

    -- Rule was found
    if m then
      local resource_id = m[abac.resource_id]
      local contexts = {}
      local index = 1
      for i, j in pairs(abac.contexts) do
        -- if context is absent in uri, take it from query params
        local context_id = m[j["id"]] or args[j["id"]]

        if context_id ~= nil then
          contexts[index] = {
            type = j["name"],
            id = context_id
          }
          index = index + 1
        end
      end

      local request = {
        consumer = {
          user_id = user_id,
          client_id = details.client_id,
          mis_client_id = mis_client_id,
          person_id = person_id
        },
        resource = {
          action = abac.action,
          type = abac.resource,
          id = resource_id
        },
        contexts = contexts
      }

      local httpc = http.new()
      local res, err =
        httpc:request_uri(
        abac.endpoint,
        {
          method = "POST",
          body = json.encode(request),
          headers = {
            accept = "application/json",
            ["Content-Type"] = "application/json",
            ["x-request-id"] = kong.ctx.plugin.correlation_id
          }
        }
      )

      httpc:close()

      if not res or res.status ~= 200 then
        send_error(403, "Access denied")
        return ngx.exit(200)
      end

      local response = json.decode(res.body)
      local result = response.data.result

      if result == false then
        send_error(403, "Access denied")
        return ngx.exit(200)
      end
    else
      send_error(401, "Abac rule was not found")
      return ngx.exit(200)
    end
  end
end

local function do_process_mis_only(config)
  local api_key = ngx.req.get_headers()["api-key"]
  if api_key ~= nil then
    rate_limiting.verify(config, api_key)
    local url = string.gsub(config.url_template, "{api_key}", api_key)

    local verify_error_msg = "Invalid api key"
    local res, err = verify_url(url, verify_error_msg)
    local mis_client_id, details, scope, broker_scope, _, _ = verify_details(res.body)

    if scope == nil then
      send_error(401, "Invalid api key")
      return ngx.exit(200)
    end

    set_mis_client_id(scope, mis_client_id, details)

    local rule = find_rule(config.rules)
    if next(config.rules) ~= nil then
      check_scopes(rule, scope, broker_scope)
    end
  else
    send_error(401, "Api key is not set")
    return ngx.exit(200)
  end
end

local function do_process(config, authorization)
  if authorization ~= nil then
    local bearer = string.sub(authorization, 8)
    rate_limiting.verify(config, bearer)
    local url = string.gsub(config.url_template, "{access_token}", bearer)

    local verify_error_msg = "Invalid access token"
    local res, err = verify_url(url, verify_error_msg)
    local mis_client_id, details, scope, broker_scope, user_id, person_id = verify_details(res.body)

    if user_id == nil or scope == nil then
      send_error(401, "Invalid access token")
      return ngx.exit(200)
    end

    ngx.req.set_header("x-consumer-id", user_id)
    ngx.req.set_header("x-person-id", person_id)
    ngx.var.upstream_x_consumer_id = user_id
    set_mis_client_id(scope, mis_client_id, details)

    local rule = find_rule(config.rules)
    if next(config.rules) ~= nil then
      check_scopes(rule, scope, broker_scope)
      check_abac(rule, user_id, mis_client_id, person_id, details)
    end
  else
    send_error(401, "Authorization header is not set or doesn't contain Bearer token")
    return ngx.exit(200)
  end
end

function MithrilHandler:access(config)
  local cookie, err = ck:new()
  kong.ctx.plugin.correlation_id = get_correlation_id()
  kong.service.request.set_header(header_name, kong.ctx.plugin.correlation_id)

  if config.mis_only == true then
    do_process_mis_only(config)
  else
    local authorization
    local field, err = cookie:get("authorization")
    if not field then
      authorization = ngx.req.get_headers()["authorization"]
    else
      authorization = "Bearer " .. field
    end

    do_process(config, authorization)
  end
end

function MithrilHandler:header_filter(config)
  local correlation_id = kong.ctx.plugin.correlation_id
  if correlation_id then
    kong.response.set_header(header_name, correlation_id)
  end
end

return MithrilHandler
