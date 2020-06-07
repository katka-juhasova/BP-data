local BasePlugin = require "kong.plugins.base_plugin"
local Logger = require "logger"

local UpstreamSelectorHandler = BasePlugin:extend()

UpstreamSelectorHandler.PRIORITY = 480

function UpstreamSelectorHandler:new()
    UpstreamSelectorHandler.super.new(self, "upstream-selector")
end

function UpstreamSelectorHandler:access(conf)
    UpstreamSelectorHandler.super.access(self)

    local headers = kong.request.get_headers()
    local header_value = headers[conf.header_name]
    if not header_value then
        return
    end

    local success, _ = kong.service.set_upstream(header_value)
    if not success then
        Logger.getInstance(ngx):logInfo({
            msg = "Upstream does not exist",
            upstream = header_value
        })
        kong.response.exit(400, "Bad request")
    end
end

return UpstreamSelectorHandler
