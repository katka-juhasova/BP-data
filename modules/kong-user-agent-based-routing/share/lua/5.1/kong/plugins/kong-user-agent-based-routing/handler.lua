local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-user-agent-based-routing.access"
local KongUserAgentBasedRoutingHandler = BasePlugin:extend()
KongUserAgentBasedRoutingHandler.PRIORITY = 10

function KongUserAgentBasedRoutingHandler:new()
	KongUserAgentBasedRoutingHandler.super.new(self, "kong-user-agent-based-routing")
end

function KongUserAgentBasedRoutingHandler:access(conf)
  KongUserAgentBasedRoutingHandler.super.access(self)
  access.execute(conf)
end

return KongUserAgentBasedRoutingHandler
