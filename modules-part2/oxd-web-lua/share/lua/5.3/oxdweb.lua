local http = require "resty.http"
local cjson = require "cjson"
local json = require "JSON"

local _M = {}

local function decode(string_data)
    local response = cjson.decode(string_data)
    return response
end

function _M.execute_http(conf, jsonBody, token, command)
    ngx.log(ngx.DEBUG, "Executing command: " .. command)
    local httpc = http.new()
    local headers = {
        ["Content-Type"] = "application/json"
    }

    if token ~= nil then
        headers.Authorization = "Bearer " .. token
        ngx.log(ngx.DEBUG, "Header token: " .. headers.Authorization)
    end

    local res, err = httpc:request_uri(conf.oxd_host .. "/" .. command, {
        method = "POST",
        body = jsonBody,
        headers = headers,
        ssl_verify = false
    })

    ngx.log(ngx.DEBUG, "Host: " .. conf.oxd_host .. "/" .. command .. " Request_Body:" .. jsonBody .. " response_body: " .. res.body)

    if pcall(decode, res.body) then
        return decode(res.body)
    else
        return { status = "error", description = "Please see the oxd log" }
    end
end

function _M.setup_client(conf)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, nil, "setup-client")

    return response
end

function _M.get_client_token(conf)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, nil, "get-client-token")
    return response
end

function _M.register_site(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "register-site")

    return response
end

function _M.update_site(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "update-site")

    return response
end

function _M.get_authorization_url(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "get-authorization-url")
    return response
end

function _M.get_token_by_code(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "get-tokens-by-code")
    return response
end

function _M.get_user_info(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "get-user-info")
    return response
end

function _M.get_logout_uri(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "get-logout-uri")
    return response
end

function _M.get_access_token_by_refresh_token(conf)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, nil, "get-access-token-by-refresh-token")
    return response
end

function _M.uma_rs_protect(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "uma-rs-protect")
    return response
end

function _M.uma_rs_check_access(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "uma-rs-check-access")
    return response
end

function _M.uma_rp_get_rpt(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "uma-rp-get-rpt")
    return response
end

function _M.uma_rp_get_claims_gathering_url(conf, token)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, token, "uma-rp-get-claims-gathering-url")
    return response
end

function _M.introspect_access_token(conf)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, nil, "introspect-access-token")
    return response
end

function _M.introspect_rpt(conf)
    local commandAsJson = json:encode(conf)
    local response = _M.execute_http(conf, commandAsJson, nil, "introspect-rpt")
    return response
end

return _M