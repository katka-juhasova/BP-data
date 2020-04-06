local BasePlugin = require "kong.plugins.base_plugin"

local URLReplace = BasePlugin:extend()

URLReplace.PRIORITY = 700

function URLReplace:new()
  URLReplace.super.new(self, "url-replace")
end


function URLReplace:access(config)
  URLReplace.super.access(self)

  path  = kong.request.get_path()
  kong.log.debug('input data: ' .. path)

  replacedPath = path:gsub(config.search_string, config.replace_string)
  kong.log.debug('setting request path to: ' .. replacedPath)

  kong.service.request.set_path(replacedPath)
end

return URLReplace
