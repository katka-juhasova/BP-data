local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local HttpsRedirect = BasePlugin:extend()

function HttpsRedirect:new()
  HttpsRedirect.super.new(self, "https-redirect")
end

function HttpsRedirect:access(conf)
  HttpsRedirect.super.access(self)

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

return HttpsRedirect
