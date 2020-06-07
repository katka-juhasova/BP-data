local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-simple-request-validator.access"


local RequestValidatorHandler = BasePlugin:extend()

function RequestValidatorHandler:new()
  RequestValidatorHandler.super.new(self, "kong-simple-request-validator")
end

function RequestValidatorHandler:access(conf)
  RequestValidatorHandler.super.access(self)
  access.execute(conf)
end

RequestValidatorHandler.PRIORITY = 949

return RequestValidatorHandler
