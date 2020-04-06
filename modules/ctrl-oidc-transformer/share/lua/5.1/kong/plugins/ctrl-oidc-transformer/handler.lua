local BasePlugin = require "kong.plugins.base_plugin"

local access = require "kong.plugins.ctrl-oidc-transformer.access"



local CtrlOidcTransformerHandler = BasePlugin:extend()



function CtrlOidcTransformerHandler:new()

  CtrlOidcTransformerHandler.super.new(self, "ctrl-oidc-transformer")

end



function CtrlOidcTransformerHandler:access(conf)

  CtrlOidcTransformerHandler.super.access(self)

  access.execute(conf)

end



return CtrlOidcTransformerHandler