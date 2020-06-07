local BasePlugin = require "kong.plugins.base_plugin"

local access = require "kong.plugins.helloworld.access"



local HelloWorldHandler = BasePlugin:extend()



function HelloWorldHandler:new()

  HelloWorldHandler.super.new(self, "helloworld")

end


function HelloWorldHandler:access(conf)

  HelloWorldHandler.super.access(self)
  print("Now in Helloworld\n")
 
  access.execute(conf)
  print("\nEXECUTE IS DONE\n")
end



return HelloWorldHandler

