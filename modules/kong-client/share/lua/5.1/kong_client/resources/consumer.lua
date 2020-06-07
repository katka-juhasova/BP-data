local ResourceObject = require "kong_client.resources.resource_object"

local Consumer = ResourceObject:extend()

Consumer.PATH = "consumers"

return Consumer
