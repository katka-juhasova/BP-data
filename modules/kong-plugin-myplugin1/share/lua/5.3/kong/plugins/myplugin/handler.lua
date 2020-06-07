local CustomHandler = require("kong.plugins.base_plugin"):extend()

function CustomHandler:header_filter(config)
	CustomHandler.super.header_filter(self)
	ngx.header["custom"] = config.content
end

return CustomHandler

