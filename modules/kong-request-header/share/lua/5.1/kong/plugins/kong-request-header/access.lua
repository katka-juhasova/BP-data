local _M = {}
local kong = kong
local fmt = string.format


local hmac = {
    ["hmac-sha1"] = function(secret, data)
        return hmac_sha1(secret, data)
    end,
    ["hmac-sha256"] = function(secret, data)
        return openssl_hmac.new(secret, "sha256"):final(data)
    end,
    ["hmac-sha384"] = function(secret, data)
        return openssl_hmac.new(secret, "sha384"):final(data)
    end,
    ["hmac-sha512"] = function(secret, data)
        return openssl_hmac.new(secret, "sha512"):final(data)
    end,
}
local function general_digest(body)
    local digest = sha256:new()
    digest:update(body or '')
    local digest_created = "SHA-256=" .. encode_base64(digest:final())
    return digest_created
end

local function response_log(conf)
    ngx.log(ngx.WARN, ngx.req.get_headers()["X-Datadog-Trace-Id"])
end


function _M.execute(conf)
    response_log(conf)
end

return _M