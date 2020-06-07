local BasePlugin = require 'kong.plugins.base_plugin'
local access = require 'kong.plugins.middleware.access'

local MiddlewareHandler = BasePlugin:extend()

MiddlewareHandler.PRIORITY = 1006 

function MiddlewareHandler:new()
  MiddlewareHandler.super.new(self, "middleware")
end

function MiddlewareHandler:access(config)
  MiddlewareHandler.super.access(self)
  access.execute(config)
end

return MiddlewareHandler
