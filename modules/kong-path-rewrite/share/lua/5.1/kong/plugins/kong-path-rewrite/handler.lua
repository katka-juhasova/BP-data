local BasePlugin = require "kong.plugins.base_plugin"

local reWriteUrlHandle = BasePlugin:extend()

reWriteUrlHandle.VERSION = "0.0.1"
reWriteUrlHandle.PRIORITY = 1

function reWriteUrlHandle:new()
  reWriteUrlHandle.super.new(self, "request-url-rewrite")
end 

function reWriteUrlHandle:access(config) 
  reWriteUrlHandle.super.init_worker(self)
  local originPath = kong.router.get_service().path
  kong.service.request.set_path(originPath..config.rewritePath)
  kong.log("originPath",originPath, "rewritePath",config.rewritePath)
end

return reWriteUrlHandle
