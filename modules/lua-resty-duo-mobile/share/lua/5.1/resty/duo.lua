local cjson = require "cjson.safe"
local http  = require "resty.http"
local hmac  = require("crypto").hmac


local ipairs        = ipairs
local pairs         = pairs
local ngx_http_time = ngx.http_time
local ngx_re_gsub   = ngx.re.gsub
local ngx_time      = ngx.time
local setmetatable  = setmetatable
local string_byte   = string.byte
local string_format = string.format
local string_upper  = string.upper
local table_concat  = table.concat
local table_insert  = table.insert
local table_sort    = table.sort


local _M = {}


local mt = { __index = _M }


local API_PREFIX = "/auth/v2/"


local POST_ENDPOINTS = {
    enroll        = true,
    enroll_status = true,
    preauth       = true,
    auth          = true,
}


local function url_encode_replace(c)
    return string_format("%%%02X", string_byte(c[1]))
end


local function url_encode(s)
    return ngx_re_gsub(s, [[([^\w\-\._~])]], url_encode_replace, "oj")
end


-- lexographically sort params and return as an ampersand-separated string
local function canon_params(params)
    if not params then
        return ""
    end


    local p, pt = {}, {}
    for k, _ in pairs(params) do
        table_insert(pt, k)
    end


    table_sort(pt)


    for _, k in ipairs(pt) do
        table_insert(p, string_format("%s=%s", k, url_encode(params[k])))
    end


    return table_concat(p, "&")
end


-- see https://duo.com/docs/authapi#authentication
local function sign(method, host, path, params, ikey, skey)
    local date   = ngx_http_time(ngx_time())
    local sign_t = { date, method, host, path, params }


    local sig = string_upper(hmac.digest("sha1", table_concat(sign_t, "\n"),
                             skey))

    return date, ngx.encode_base64(string_format("%s:%s", ikey, sig))
end
_M.sign = sign


local function duo_request(self, endpoint, api_params)
    local is_post = POST_ENDPOINTS[endpoint]


    local method = is_post and "POST" or "GET"
    local params = canon_params(api_params)
    local path   = string_format("https://%s%s%s", self.host, API_PREFIX,
                                 endpoint)


    local date, sig = sign(method, self.host, API_PREFIX .. endpoint, params,
                           self.ikey, self.skey)


    local headers = {
        ["Date"] = date,
        ["Authorization"] = "Basic " .. sig,
    }


    local req_tab = {
        method  = method,
        headers = headers,
    }
    if is_post then
        req_tab.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req_tab.body = params
    else
        req_tab.query = params
    end


    return http.new():request_uri(path, req_tab)
end
_M.duo_request = duo_request


local function read_duo_response(res, err)
    if not res then
        return nil, err
    end


    if res.status ~= 200 then
        return nil, res.body
    end


    local body, err = cjson.decode(res.body)
    if err then
        return nil, "Failed to decode Duo API response body"
    end


    if body.stat ~= "OK" then
        return nil, res.body
    end


    return body.response
end


function _M:enroll(username)
    return read_duo_response(duo_request(self, "enroll", {
        username = username,
    }))
end


function _M:preauth(username, ip)
    return read_duo_response(duo_request(self, "preauth", {
        username = username,
        ipaddr   = ip,
    }))
end


function _M:auth(username, factor, opts)
    local params = {
        username = username,
        factor   = factor,
    }


    for k, v in pairs(opts) do
        params[k] = v
    end


    return read_duo_response(duo_request(self, "auth", params))
end


function _M.new(params)
    return setmetatable(params, mt)
end


return _M
