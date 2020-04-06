local BasePlugin = require "kong.plugins.base_plugin"

local ForceSSL = BasePlugin:extend()

function ForceSSL:new()
  ForceSSL.super.new(self, "force-ssl")
end

function ForceSSL:access(conf)
  ForceSSL.super.access(self)

  local headers = ngx.req.get_headers()
  local proto
  if headers["x-forwarded-proto"] then
    proto = headers["x-forwarded-proto"]
  else
    proto = ngx.var.scheme
  end
  if proto ~= "https" then
    local host = ngx.var.host
    local uri = ngx.var.request_uri
    return ngx.redirect("https://" .. host .. uri, ngx.HTTP_MOVED_PERMANENTLY)
  end
end

return ForceSSL
