local cjson = require "cjson"
local http = require "resty.http"
local url = require "socket.url"


local _M = {}

-- assembly http request body
-- @param `conf` token_agent configure
-- @return http request body, nil where err
local function assembly_body(conf)
    local up = ngx.req.get_headers()["X-App-Name"]
    local uid = ngx.req.get_headers()["X-User-Id"]
    local sid = ngx.req.get_headers()["X-Access-Token"]

    local verify_body_func = loadstring(conf.verify_body_func)
    if not verify_body_func then
        ngx.log(ngx.ERR, "[token_agent] loadstring verify_body_func err:", conf.verify_body_func)
        return nil
    end
    
    return verify_body_func(){
        up = up, 
        uid = uid, 
        sid = sid,
    }
end


-- check token status
-- @param `conf` token_agent configure
-- @param `resp` the response of http, see lua-resty-http request_uri function
-- @return true or false, err where err
local function check_response(conf, resp)
    local verify_check_func = loadstring(conf.verify_check_func)
    if not verify_check_func then
        ngx.log(ngx.ERR, "[token_agent] loadstring verify_check_func err:", conf.verify_check_func)
        return nil
    end

    return verify_check_func()(resp)
end


function _M.execute(conf)
    local body = assembly_body(conf)
    ngx.log(ngx.DEBUG, "token-agent verify_url:",conf.verify_url, ", body :", body)

    local httpc = http.new()
    httpc:set_timeout(conf.timeout)
    local res, err = httpc:request_uri(
        conf.verify_url .. '?' .. (body or ""),
        {
            method = conf.method,
            body = body,
            headers = {
                ["Content-Type"] = conf.content_type,
                ["X-Forwarded-For"] = ngx.req.get_headers()["X-Forwarded-For"]
            }
        }
    )
    ngx.log(ngx.DEBUG, "[token_agent] res.status:",res.status, ",res.body:",res.body)

    if not res then
        ngx.log(ngx.ERR, "[token_agent] request verify_url err:", err)
        return false
    end

    return check_response(conf, res)
end


return _M
