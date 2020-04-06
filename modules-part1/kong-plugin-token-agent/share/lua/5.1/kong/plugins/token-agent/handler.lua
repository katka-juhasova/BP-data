local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.cmd.utils.log"
local responses = require "kong.tools.responses"

local access = require "kong.plugins.token-agent.access"


local TokenAgentHandler = BasePlugin:extend()


function TokenAgentHandler:new()
    TokenAgentHandler.super.new(self, "token-agent")
end


function TokenAgentHandler:access(config)
    TokenAgentHandler.super.access(self)

    if not access.execute(config) then
        responses.send(ngx.HTTP_UNAUTHORIZED)
    end
end


return TokenAgentHandler
