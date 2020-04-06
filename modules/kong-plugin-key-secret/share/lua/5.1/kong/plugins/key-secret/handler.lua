local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.cmd.utils.log"
local responses = require "kong.tools.responses"
local json = require "cjson"

local access = require "kong.plugins.key-secret.access"

local KeySecretHandler = BasePlugin:extend()

function KeySecretHandler:new()
    KeySecretHandler.super.new(self, "key-secret")
end


function KeySecretHandler:access(config)
    KeySecretHandler.super.access(self)

    if not access.execute(config) then
        responses.send(ngx.HTTP_FORBIDDEN)
    end

end

return KeySecretHandler

