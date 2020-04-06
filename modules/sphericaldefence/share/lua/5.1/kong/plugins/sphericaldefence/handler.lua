local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.sphericaldefence.access"

local SphericalDefenceHandler = BasePlugin:extend()

SphericalDefenceHandler.PRIORITY = 900

function SphericalDefenceHandler:new()
  SphericalDefenceHandler.super.new(self, "sphericaldefence")
end

function SphericalDefenceHandler:access(conf)
  SphericalDefenceHandler.super.access(self)
  access.execute(conf)
end

return SphericalDefenceHandler