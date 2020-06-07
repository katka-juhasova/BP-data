local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.cmd.utils.log"
local cjson = require "cjson.safe"

local DebugHandler = BasePlugin:extend()

function DebugHandler:new()
    DebugHandler.super.new(self, "debug")
end

function DebugHandler:header_filter(config)
    DebugHandler.super.header_filter(self)

    local ctx = ngx.ctx or {}
    local encoded = nil
    if ctx then
        local ctx_balancer_address = ctx.balancer_address
        local balancer_address = {}
        if ctx_balancer_address then
            balancer_address = {
                host=ctx_balancer_address.host,
                hostname=ctx_balancer_address.hostname,
                type=ctx_balancer_address.type,
                retries=ctx_balancer_address.retries,
                ip=ctx_balancer_address.ip,
                port=ctx_balancer_address.port,
                try_count=ctx_balancer_address.try_count,
                tries=ctx_balancer_address.tries,
                connect_timeout=ctx_balancer_address.connect_timeout,
                read_timeout=ctx_balancer_address.read_timeout,
                send_timeout=ctx_balancer_address.send_timeout,
            }
        end
        
        encoded = cjson.encode({
            api=ctx.api,
            plugins_for_request=ctx.plugins_for_request,
            router_matches=ctx.router_matches,
            balancer_address=balancer_address,
        })
    end

    local header = ngx.header
    header["X-Kong-API"] = encoded
end

return DebugHandler

