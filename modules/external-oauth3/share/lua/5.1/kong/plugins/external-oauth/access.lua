-- 1. For an incoming call, we get its Beaer token
-- 2, Make a http call to get token information
-- 3. Log down the token information

local _M = {}
local pl_stringx = require "pl.stringx"
local crypto = require "crypto"

function _M.run(conf)
     -- Check if the API has a request_path and if it's being invoked with the path resolver
    local path_prefix = ""

    if ngx.ctx.api.uris ~= nil then
        for index, value in ipairs(ngx.ctx.api.uris) do
            if pl_stringx.startswith(ngx.var.request_uri, value) then
                path_prefix = value
                break
            end
        end

        if pl_stringx.endswith(path_prefix, "/") then
            path_prefix = path_prefix:sub(1, path_prefix:len() - 1)
        end

    end

    ngx_log(DEBUG, "executing plugin \"", self._name, "\": " .. ngx.req.get_method())
    ngx_log(DEBUG, "headers: \n")
    local h = ngx.req.get_headers()
    for k, v in pairs(h) do
        ngx_log(DEBUG, k .. ":" .. v .."\n")
    end

end

return _M
