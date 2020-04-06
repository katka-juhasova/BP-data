local _M = {}

local urlDecoder = require "gonapps.url.decoder"

function _M.parse(queryString, parameters)
    if parameters == nil then
        parameters = {}
    end
    for pair in string.gmatch(queryString, "([^&]+)") do
        for key, value in string.gmatch(pair, "([^=]+)=([^=]+)") do
            parameters[urlDecoder.decode(key)] = urlDecoder.decode(value)
        end
    end
    return parameters
end

return _M
