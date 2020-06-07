local ResponseBuilder = {
    ERR_PARSE_ERROR = -32700, -- Error code for "Parse error" error
    ERR_INVALID_REQUEST = -32600, -- Error code for "Invalid request" error
    ERR_METHOD_NOT_FOUND = -32601, -- Error code for "Method not found" error
    ERR_INVALID_PARAMS = -32602, -- Error code for "Invalid params" error
    ERR_INTERNAL_ERROR = -32603, -- Error code for "Internal error" error
    ERR_SERVER_ERROR = -32000, -- Error code for "Server error" error
    ERR_EMPTY_REQUEST = -32097, -- Error code for "Empty request" error
}

ResponseBuilder.messages = {
    [ResponseBuilder.ERR_PARSE_ERROR] = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
    [ResponseBuilder.ERR_INVALID_REQUEST] = 'The JSON sent is not a valid Request object.',
    [ResponseBuilder.ERR_METHOD_NOT_FOUND] = 'The method does not exist / is not available.',
    [ResponseBuilder.ERR_INVALID_PARAMS] = 'Invalid method parameter(s).',
    [ResponseBuilder.ERR_INTERNAL_ERROR] = 'Internal JSON-RPC error.',
    [ResponseBuilder.ERR_SERVER_ERROR] = 'Server error',
    [ResponseBuilder.ERR_EMPTY_REQUEST] = 'Empty request.',
}

--- Create new response builder
-- @param[type=table] json Json encoder instance
function ResponseBuilder:new(json)
    assert(type(json) == "table", "Parameter 'json' is required and should be a table!")
    local builder = setmetatable({}, ResponseBuilder)
    self.__index = self

    builder.json = json
    return builder
end

--- Get a proper formated json error
-- @param[type=int] code Error code
-- @param[type=string] message Error message
-- @param[type=table] data Additional error data
-- @param[type=number] id Request id
-- @return[type=string]
function ResponseBuilder:build_json_error(code, message, data, id)
    local code = self.messages[code] and code or self.ERR_SERVER_ERROR
    local message = message or self.messages[code]
    local data = data and self.json.encode(data) or 'null'
    local id = id or 'null'

    return '{"jsonrpc":"2.0","error":{"code":' .. tostring(code) .. ',"message":"' .. message .. '","data":' .. data .. '},"id":' .. id .. '}'
end

return ResponseBuilder