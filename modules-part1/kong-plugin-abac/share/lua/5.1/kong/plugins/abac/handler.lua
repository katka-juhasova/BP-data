local BasePlugin = require "kong.plugins.base_plugin"
local json = require "dkjson"
local http = require "resty.http"

local AbacHandler = BasePlugin:extend()

AbacHandler.PRIORITY = 760

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
      request_id = ngx.ctx.correlationid_header_value,
      code = status_code
    },
    error = {
      type = type,
      message = message
    }
  }
  ngx.say(json.encode(error))
end

function AbacHandler:new()
  AbacHandler.super.new(self, "abac")
end

function AbacHandler:access(config)
  AbacHandler.super.access(self)

  local m, err = ngx.re.match(ngx.var.request_uri, config.rule)

  -- Rule was found
  if m then
    local resource_id = m[config.resource_id]
    local contexts = {}
    for i, j in pairs(config.contexts) do
      contexts[i] = {
        type = j["name"],
        id = m[j["id"]]
      }
    end

    local metadata = json.decode(ngx.req.get_headers()["x-consumer-metadata"])
    local request = {
      consumer = {
        user_id = ngx.req.get_headers()["x-consumer-id"],
        client_id = metadata.client_id
      },
      resource = {
        action = config.action,
        type = config.resource,
        id = resource_id
      },
      contexts = contexts
    }

    local httpc = http.new()
    local res, err =
      httpc:request_uri(
      config.endpoint,
      {
        method = "POST",
        body = json.encode(request),
        headers = {
          accept = "application/json",
          ["Content-Type"] = "application/json"
        }
      }
    )

    httpc:close()

    if not res or res.status ~= 200 then
      send_error(403, "Access denied")
      return ngx.exit(200)
    end

    local response = json.decode(res.body)
    local result = response.result

    if result == false then
      send_error(403, "Access denied")
      return ngx.exit(200)
    end
  end
end

return AbacHandler
