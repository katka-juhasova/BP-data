local cppjwt = require('libcppjwt')
local json = require('cjson')

local M = {}

function M.decode_raw(token)
    return cppjwt.decode(token)
end

function M.decode(token)
    return json.decode(M.decode_raw(token))
end

function M.verify(token, key)
    return cppjwt.verify(token, key)
end

return M
