local BasePlugin = require "kong.plugins.base_plugin"

local AddHeaderHandler = BasePlugin:extend()

AddHeaderHandler.PRIORITY = 801

function AddHeaderHandler:new()
    AddHeaderHandler.super.new(self, "add-header")
end

function AddHeaderHandler:access(conf)
    AddHeaderHandler.super.access(self)

    local header_name = conf.header_name
    local header_value = conf.header_value

    kong.service.request.add_header(header_name, header_value)
end

return AddHeaderHandler
