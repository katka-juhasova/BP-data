local Object = require "classic"
local Service = require "kong_client.resources.service"
local Route = require "kong_client.resources.route"
local Plugin = require "kong_client.resources.plugin"
local Consumer = require "kong_client.resources.consumer"
local Upstream = require "kong_client.resources.upstream"

local KongClient = Object:extend()

local function patch_http_client(http_client, transform_response)
    local NewHttpClient = {}

    function NewHttpClient:send(request) -- luacheck: ignore self
        local response, err = http_client:send(request)

        if transform_response then
            return transform_response(request, response, err)
        end

        return response, err
    end

    return NewHttpClient
end

function KongClient:new(config)
    self.http_client = patch_http_client(config.http_client, config.transform_response)

    self.services = Service(self.http_client)
    self.routes = Route(self.http_client)
    self.plugins = Plugin(self.http_client)
    self.consumers = Consumer(self.http_client)
    self.upstreams = Upstream(self.http_client)
end

return KongClient
