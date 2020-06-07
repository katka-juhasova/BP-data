local BasePlugin = require "kong.plugins.base_plugin"
local responses  = require "kong.tools.responses"

local HttpHandler = BasePlugin:extend()

function HttpHandler:new()
  HttpHandler.super.new(self, "http-to-https")
end

function HttpHandler:access(conf)
  HttpHandler.super.access(self)

  if ngx.var.https ~= "on" then
    return ngx.redirect("https://" .. ngx.var.host .. ngx.var.request_uri, ngx.HTTP_MOVED_PERMANENTLY)
  end
end

return HttpHandler
