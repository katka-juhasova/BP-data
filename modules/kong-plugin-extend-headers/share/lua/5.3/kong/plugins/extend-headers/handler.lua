local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.cmd.utils.log"
local json = require "cjson"

local ExtendHeadersHandler = BasePlugin:extend()

function ExtendHeadersHandler:new()
    ExtendHeadersHandler.super.new(self, "extend-headers")
end

function ExtendHeadersHandler:header_filter(config)
    ExtendHeadersHandler.super.header_filter(self)

    local ctx = ngx.ctx
    local header = ngx.header
    
    if ctx.KONG_PROXIED then
        header["X-Kong-Proxied"] = "true"
    else
        header["X-Kong-Proxied"] = "false"
    end
end

return ExtendHeadersHandler

