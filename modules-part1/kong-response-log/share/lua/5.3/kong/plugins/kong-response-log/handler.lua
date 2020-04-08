local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-response-log.access"


local UpstreamHMACHandler = BasePlugin:extend()

function UpstreamHMACHandler:new()
    UpstreamHMACHandler.super.new(self, "kong-response-log")
end

function UpstreamHMACHandler:body_filter(conf)
    UpstreamHMACHandler.super.body_filter(self)
    access.execute(conf)
end

UpstreamHMACHandler.PRIORITY = 666

return UpstreamHMACHandler