local function check_func(given_func_str)
    local f = loadstring(given_func_str)
    if not f then
        return false, "invalid function"
    end

    return true, nil
end


return {
    fields = {
        verify_url = { required = true, type = "url" },
        method = { default = "POST", enum = {"POST"} },
        content_type = { default = "application/json", enum = { "application/json","application/x-www-form-urlencoded" } },
        timeout = { default = 10000, type = "number" },
        keepalive = { default = 60000, type = "number" },
        
        -- verify_body_func(table)
        -- @param table {up="xx", uid="xx", sid="xx"}
        -- @return body string, nil where err
        verify_body_func = {type = "string", func = check_func, required = true},
       
        -- verify_check_func(response)
        -- @param response the response of http, see lua-resty-http request_uri function
        -- @return true or false, nil where err
        verify_check_func = {type = "string", func = check_func, required = true},
    }
}

