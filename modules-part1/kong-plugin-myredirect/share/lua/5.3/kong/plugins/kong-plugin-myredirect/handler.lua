local BasePlugin = require "kong.plugins.base_plugin"

local MyPluginHandler = BasePlugin:extend()

function MyPluginHandler:new()
  MyPluginHandler.super.new(self, "myredirect")
end
  
function MyPluginHandler:header_filter(config)
    local status = kong.response.get_status()
    if status ~= 301 and status ~= 302 then
        return
    end
    local location  = kong.response.get_header('Location')
    if not location then
        return
    end
    local index = string.find(location, '://')
    if index then
        location = string.sub(location,index+3)
    else
        return
    end
    index = string.find(location, '/')
    if index then
        location = string.sub(location,index)
    else
        return
    end
    local sub_config = nil
    if config['http_code1']['code'] == status then
        sub_config = config['http_code1']
    elseif config['http_code2']['code'] == status then
        sub_config = config['http_code2']
    end
    if sub_config then
        if sub_config['host'] then
            kong.response.set_header("Location", sub_config['host'] .. location)
        else
            kong.response.set_header("Location", ngx.var.scheme..'://'..ngx.var.host..location)
        end
    else
        ngx.log('redirect to out side')
    end
end

MyPluginHandler.PRIORITY = 802
MyPluginHandler.VERSION = "0.1.0"

return MyPluginHandler