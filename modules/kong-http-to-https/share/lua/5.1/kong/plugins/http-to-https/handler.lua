local BasePlugin  = require "kong.plugins.base_plugin"
local HttpHandler = BasePlugin:extend()

HttpHandler.VERSION  = "1.0.0"
HttpHandler.PRIORITY = 10

function HttpHandler:new()
  HttpHandler.super.new(self, "http-to-https")
end

function HttpHandler:access(conf)
  HttpHandler.super.access(self)

  local headers = ngx.req.get_headers()
  local proto   = ngx.var.scheme

  if headers["x-forwarded-proto"] then
    proto = headers["x-forwarded-proto"]
  end

  if proto ~= "https" then
    local host = ngx.var.host
    local uri  = ngx.var.request_uri

    return ngx.redirect("https://" .. host .. uri, ngx.HTTP_MOVED_PERMANENTLY)
  end
end

return HttpHandler
