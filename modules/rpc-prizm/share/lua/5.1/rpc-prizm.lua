----------------------
-- Prizm is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @license MIT

--- Request factory
local Request = require "rpc-prizm.request"

--- The lua gateway class definition
local Prizm = {
    REQ_PREF = 'REQ', -- Request prefix (used in log message)
}

Prizm.HTTP_POST = 8

--- Create new Gate instance
-- @param[type=table] config Table of configuration options
-- @return[type=table] The new instance of Gate
function Prizm:new(config)
    config.hooks = config.hooks or {}
    config.hooks.pre = config.hooks.pre or function() end
    config.hooks.pre_request = config.hooks.pre_request or function() end
    config.hooks.post = config.hooks.post or function() end

    assert(type(config.ngx) == "table", "Parameter 'ngx' is required and should be a table!")
    assert(type(config.json) == "table", "Parameter 'json' is required and should be a table!")
    assert(type(config.router) == "table", "Parameter 'router' is required and should be a table!")
    assert(type(config.logger) == "table", "Parameter 'logger' is required and should be a table!")
    assert(type(config.proxy) == "table", "Parameter 'proxy' is required and should be a table!")
    assert(type(config.response_builder) == "table", "Parameter 'response_builder' is required and should be a table!")
    assert(type(config.hooks.pre) == "function", "Parameter 'pre' is required and should be a function!")
    assert(type(config.hooks.post) == "function", "Parameter 'post' is required and should be a function!")

    -- Define metatable
    local prizm = setmetatable({}, Prizm)
    self.__index = self

    -- Define services and configs

    prizm.hooks = config.hooks
    prizm.ngx = config.ngx
    prizm.json = config.json
    prizm.router = config.router
    prizm.logger = config.logger
    prizm.proxy = config.proxy
    prizm.response_builder = config.response_builder
    prizm.responses = {}

    return prizm
end

--- Create new Prizm instance. Initialize ngx dependent properties
-- @param[type=table] config Table of configuration options
-- @return[type=table] The new instance of Prizm
function Prizm:init(config)
    -- Create new tmp instance
    local prizm = self:new(config)

    -- Check request method
    if 'POST' ~= prizm.ngx.req.get_method() then
        prizm.ngx.say(self.response_builder:build_json_error(self.response_builder.ERR_INVALID_REQUEST, 'Only POST requests are allowed'))
        prizm.ngx.exit(prizm.ngx.HTTP_OK)
    end

    -- Build config
    prizm.ngx.req.read_body() -- explicitly read the req body

    if not prizm:is_not_empty() then
        prizm.ngx.say(self.response_builder:build_json_error(self.response_builder.ERR_EMPTY_REQUEST))
        prizm.ngx.exit(prizm.ngx.HTTP_OK)
    end

    return prizm
end

--- Check if request is empty
-- @return[type=boolean]
function Prizm:is_not_empty()
    return self:get_body() ~= '' and true or false
end

--- Get ngx request body
-- @return[type=string]
function Prizm:get_body()
    if not self.body then
        self.body = self.ngx.req and self.ngx.req.get_body_data() or ''
    end

    return self.body
end

--- Parse raw body
-- @return[type=table]
function Prizm:get_data()
    if not self.data then
        self.data = {}
        if self:get_body() then
            local success, res = pcall(self.json.decode, self:get_body())
            self.data = success and res or {}
        end
    end

    return self.data
end

--- Check if request is a batch
-- @return[type=boolean]
function Prizm:is_batch()
    if not self.batch then
        local data = self:get_data()
        self.batch =  data and data[1] and ('table' == type(data[1])) and true or false
    end

    return self.batch
end

--- Get request collection
-- @return[type=table] The table of requests
function Prizm:get_requests()
    if not self.requests then
        self.requests = {}
        local data = self:get_data()
        if self:is_batch() then
            for _, rdata in ipairs(data) do
                table.insert(self.requests, Request:new(rdata, self.json))
            end
        else
            table.insert(self.requests, Request:new(data, self.json))
        end
    end

    return self.requests
end

--- Get request collection prepared for ngx.location.capture_multi call
-- @return[type=table] The table of responses
function Prizm:run()
    -- Execute 'pre' middleware
    if false == self.hooks.pre(self) then
        return ngx.exit(ngx.HTTP_OK)
    end

    local map_requests = self:prepare_map_requests(self:get_requests())

    if  next(map_requests) ~= nil then
        local proxy_responses  = self.proxy:do_requests(map_requests)
        for _,v in ipairs(proxy_responses) do
            table.insert(self.responses, v)
        end
    end

    -- Execute 'post' middleware
    if false == self.hooks.post(self) then
        return ngx.exit(ngx.HTTP_OK)
    end

    return self.responses
end

---Create a map of requests associated with endpoints
-- @param[type=table] requests Table of rpc requests
-- @return[type=table] The table of requests
function Prizm:prepare_map_requests(requests)
    local map_requests = {}

    for _, request in ipairs(requests) do
        self.logger:write_log(request:get_body(), Prizm.REQ_PREF)
        if request:is_valid() then
            local pre_request_result = self.hooks.pre_request(request, self)
            if type(pre_request_result) == 'string' then
                table.insert(self.responses, pre_request_result)
            else
                local addr, err = self.router:get_address(request:get_route())
                if addr then
                    map_requests[addr] = map_requests[addr] or {}
                    table.insert(map_requests[addr], request)
                else
                    table.insert(self.responses,  self.response_builder:build_json_error(self.response_builder.ERR_SERVER_ERROR, err, request:get_body(), request:get_id()))
                end
            end
        else
            table.insert(self.responses, self.response_builder:build_json_error(self.response_builder.ERR_INVALID_REQUEST, nil, request:get_body(), request:get_id()));
        end
    end

    return map_requests;
end

--- Get responses as a string
-- @return[type=string]
function Prizm:get_result()
    if false == self:is_batch() then
        return self.responses[1]
    end

    return '[' .. table.concat(self.responses, ",") .. ']'
end

--- Print all responses and exit
function Prizm:print_responses()
    ngx.say(self:get_result())

    ngx.exit(ngx.HTTP_OK)
end

return Prizm