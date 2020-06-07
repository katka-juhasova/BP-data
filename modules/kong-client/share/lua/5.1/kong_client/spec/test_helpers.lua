local kong_helpers = require "spec.helpers"
local KongClient = require "kong_client"
local cjson = require "cjson"

local function is_error(response)
    return response.status >= 400 or response.status < 100
end

local function try_decode(raw_body)
    local parsed_body = {}

    if #raw_body > 0 then
        parsed_body = cjson.decode(raw_body)
    end

    return parsed_body
end

local function handle_admin_client_response(request, response, err)
    assert(response, err)

    local raw_body = assert(response:read_body())

    local body = try_decode(raw_body)

    if is_error(response) then
        error({ method = request.method, path = request.path, status = response.status, body = body })
    end

    return body
end

local function create_kong_client()
    return KongClient({
        http_client = kong_helpers.admin_client(),
        transform_response = handle_admin_client_response
    })
end

local function add_json_header(request)
    if type(request.body) == "table" then
        if not request.headers then
            request.headers = {}
        end

        request.headers["Content-Type"] = "application/json"
    end
end

local function create_request_sender(http_client)
    return function(request)
        add_json_header(request)

        local response = assert(http_client:send(request))

        local raw_body = assert(response:read_body())
        local success, parsed_body = pcall(cjson.decode, raw_body)

        return {
            body = success and parsed_body or raw_body,
            headers = response.headers,
            status = response.status
        }
    end
end

return {
    create_kong_client = create_kong_client,
    create_request_sender = create_request_sender
}
