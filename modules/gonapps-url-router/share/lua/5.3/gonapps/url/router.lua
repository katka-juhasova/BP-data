local _M = {}
local regex = require "rex_pcre"
local urlDecoder = require "gonapps.url.decoder"
local Path = {}
Path.__index = Path

function Path.new(pattern, method, callback)
    local self = setmetatable({}, Path)
    self.regex = assert(regex.new(pattern))
    self.method = method
    self.callback = callback
    return self
end

function Path:match(pattern, method)
    if self.method == method then
        local _, _, result = self.regex:tfind(pattern)
        return result
    else
        return nil
    end
end

function _M.new()
    local self = setmetatable({}, {__index = _M})
    self.paths = {}
    return self
end

function _M:setCallback(pattern, method, callback)
    table.insert(self.paths, Path.new(pattern, method, callback))
end

function _M:route(client)
    local result
    for _, path in ipairs(self.paths) do
        result = path:match(client.request.pathInfo, client.request.method)
        if result ~= nil then
            for key, value in pairs(result) do
                if type(key) == "string" then
                    client.request.parameters[urlDecoder.rawDecode(key)] = urlDecoder.rawDecode(value)
                end
            end
            local statusCode, headers, body = path.callback(client.request)
            client.response:writeVersion(client.request.versionMajor, versionMinor)
            client.response:writeStatusCode(statusCode)
            for key, value in pairs(headers) do
                client.response:writeHeader(key, value)
            end
            client.response:writeBody(body)
            return
        end
    end
    client.response:writeVersion(client.request.versionMajor, versionMinor)
    client.response:writeStatusCode(404)
    client.response:writeBody("404 Not Found")
end

return _M
