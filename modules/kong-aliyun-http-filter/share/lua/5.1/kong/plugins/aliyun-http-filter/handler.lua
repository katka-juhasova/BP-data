local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local HttpFilterHandler = BasePlugin:extend()

function HttpFilterHandler:new()
  HttpFilterHandler.super.new(self, "aliyun-http-filter")
end

function HttpFilterHandler:access(conf)
  HttpFilterHandler.super.access(self)

  local filter = {
    http = conf.http,
    https = conf.https
  }
  local headers = ngx.req.get_headers()
  local proto = headers["x-forwarded-proto"]
  if not filter[proto] then
    ngx.status = 403
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    ngx.say(string.format("{\"message\":\"%s protocol not supported\"}", proto))
    return ngx.exit(ngx.status)
  end
end

return HttpFilterHandler
