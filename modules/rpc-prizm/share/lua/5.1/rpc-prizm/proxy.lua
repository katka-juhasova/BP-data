local HttpStatuses = require 'rpc-prizm.http_statuses'

local Proxy = {
    REQ_PREF = 'REQ', -- Request prefix (used in log message)
    RESP_PREF = 'RESP', -- Response prefix (used in log message)
}

---Create new reverse proxy instance
-- @param[type=table] ngx nginx instance
-- @param[type=table] logger logger instance
-- @param[type=table] response_builder response builder instance
-- @return[type=table] proxy instance
function Proxy:new(ngx, logger, response_builder)
    local proxy = setmetatable({}, Proxy)
    self.__index = self

    proxy.ngx = ngx
    proxy.logger = logger
    proxy.response_builder = response_builder

    return proxy

end

---Send requests to services and handle responses
-- @param[type=table] map_requests Map of rpc requests associated with endpoints
-- @return[type=table] Responses from services
function Proxy:do_requests(map_requests)
    local ngx_requests, request_groups = self:get_ngx_requests(map_requests)
    local ngx_responses = { self.ngx.location.capture_multi(ngx_requests) }
    local rpc_responses = self:handle_responses(ngx_responses, request_groups)

    return rpc_responses
end

---Build nginx requests from rpc requests
-- @param[type=table] map_requests Map of rpc requests associated with endpoints
-- @return[type=table] ngx_requests Array of nginx requests to services, each request may contain several rpc requests
-- @return[type=table] request_groups Array of rpc requests grouped by endpoints for matching with services responses
function Proxy:get_ngx_requests(map_requests)
    local ngx_requests = {}
    local request_groups = {}
    for addr,requests in pairs(map_requests) do
        table.insert(request_groups, {addr=addr, reqs=requests})
        table.insert(ngx_requests, self:get_ngx_request(addr, requests))
    end

    return ngx_requests, request_groups
end

--- Build a request in format acceptable by nginx
-- @param[type=table] addr Request uri
-- @param[type=table] requests Array of rpc requests
-- @return[type=table] Nginx request
function Proxy:get_ngx_request(addr, requests)
    local rpc_requests = {}
    for _,request in ipairs(requests) do
        table.insert(rpc_requests, request:get_body())
    end

    local body = ''
    if #requests > 1 then
        body = '[' .. table.concat(rpc_requests, ",") .. ']'
    else
        body = rpc_requests[1]
    end
    return { addr, { method = 8, body = body, args = self.ngx.req.get_uri_args(), ctx = self.ngx.ctx } }
end

--- Handle responses from services
-- @param[type=table] ngx_responses Reponses from services
-- @param[type=table] request_groups  Array of rpc requests grouped by endpoints for matching with services responses
-- @return[type=table] Array of texts of responses
function Proxy:handle_responses(ngx_responses, request_groups)
    local responses = {}
    for i, response in ipairs(ngx_responses) do
        local resp_body = self:clean_response(response.body)
        if self:is_valid_json(resp_body) then
            table.insert(responses, self:trim_brackets(resp_body))
            -- Push to log
            self.logger:write_log(self:trim_brackets(resp_body), Proxy.RESP_PREF)
        elseif self.ngx.HTTP_OK ~= response.status then
            local response_msg = HttpStatuses[response.status] or 'Unknown error'
            local data = resp_body
            for _,request in ipairs(request_groups[i]['reqs']) do
                table.insert(responses,  self.response_builder:build_json_error(
                        self.response_builder.ERR_SERVER_ERROR, response.status .. ' ' .. response_msg, data, request:get_id()
                ))
            end
        else
            for _, request in ipairs(request_groups[i]['reqs']) do
                table.insert(responses,  self.response_builder:build_json_error(
                        self.response_builder.ERR_SERVER_ERROR, 'Server error. Bad JSON-RPC response.', nil, request:get_id()
                ))
            end
        end
    end

    return responses
end

--- Quick way to find invalid responses
-- @param[type=string] str Input string to check
function Proxy:is_valid_json(str)
    local first_char = string.sub(str, 1, 1)
    local last_char = string.sub(str, -1)

    return ('' ~= str) and (('{' == first_char or '[' == first_char) and ('}' == last_char or ']' == last_char))
end

--- Clean response (trim)
-- @param[type=table] response Nginx response
-- @return[type=string] Trimmed string
function Proxy:clean_response(response)
    local response_body = response.body or response
    return response_body:match'^()%s*$' and '' or response_body:match'^%s*(.*%S)'
end

--- Remove brackets '[]' from response, it is necessary to glue all responses to one
-- @param[type=string] str Input string to trim
-- @return[type=string] Trimmed string
function Proxy:trim_brackets(str)
    local _, i1 = string.find(str,'^%[*')
    local i2 = string.find(str,'%]*$')
    return string.sub(str, i1 + 1, i2 - 1)
end

return Proxy