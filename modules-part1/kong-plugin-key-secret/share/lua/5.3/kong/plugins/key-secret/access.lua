local table = require "table"
local string = require "string"


local _M = {}

local function get_secret(key)
    return string.lower(ngx.md5((key or "") .. "qianbao"))
end
    
local function check_is_app_valid(args)
    local sign = args.sign or "nil"
    args.sign = nil

    args["app_secret"] = get_secret(args["app_key"])
    local key_list = {"method", "ts", "app_key", "app_secret"}

    local param_list = {}
    for _, keyword in ipairs(key_list) do
        local val = args[keyword]
        if val == nil then
            return false
        end
        if type(val) == "table" then
            table.insert(param_list, keyword .. "=" .. table.concat(val, ", "))
        else
            table.insert(param_list, keyword .. "=" ..val)
        end
    end
    table.sort(param_list)
    local sign_ok = ngx.md5(table.concat(param_list, "&"))
    ngx.log(ngx.INFO, "[check_is_app_valid] [sign_ok]:" .. sign_ok .. "[sign]:" .. sign)

    return (string.lower(sign) == string.lower(sign_ok))
end


function _M.execute(conf)
    local uri_args = ngx.req.get_uri_args()
    return check_is_app_valid(uri_args)
end


return _M