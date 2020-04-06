local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-path-based-routing.access"
local KongPathBasedRoutingHandler = BasePlugin:extend()
KongPathBasedRoutingHandler.PRIORITY = 10

function KongPathBasedRoutingHandler:new()
	KongPathBasedRoutingHandler.super.new(self, "kong-path-based-routing")
end

function KongPathBasedRoutingHandler:access(conf)
  KongPathBasedRoutingHandler.super.access(self)
  access.execute(conf)
end

return KongPathBasedRoutingHandler
