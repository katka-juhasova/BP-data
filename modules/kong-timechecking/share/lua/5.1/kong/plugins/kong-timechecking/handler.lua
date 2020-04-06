local BasePlugin = require "kong.plugins.base_plugin"
local os = require "os"

local Timing = BasePlugin:extend()
local kong = kong
local ipairs = ipairs
local pairs = pairs



Timing.VERSION = "0.1.0-4"
Timing.PRIORITY = 999


function Timing:new()
    Timing.super.new(self, "kong-timechecking")
end

function doExpiryTiming(conf)

    local exit, errE = isExist(conf.methods, kong.request.get_method())



    if errE ~= nil then
        return {}, errE
    end

    local parse_body, err = parseBody(conf)


    if err ~= nil then
        return {}, {status = 403, message = "Request invalid."}
    end




    if not parse_body[conf.attr] then
        return {}, {
            status = 403,
            message = "Request invalid."
        }
    end





    local timeExpiry = parse_body[conf.attr]

    if (os.time() - timeExpiry) > conf.time_expiry == true then


        return {}, {
            status = 403,
            message = "Request invalid."
        }
    end


    return {}, nil
end

function Timing:access(conf)
    Timing.super.access(self)


    if not conf.attr or not conf.methods or not conf.time_expiry then
        return kong.response.exit(403, {
            message = "Request invalid."
        })
    end


    local ok, err = doExpiryTiming(conf)


    if err ~= nil then
        return kong.response.exit(200, {
            message = err.message,
            status = err.status
        })
    end

end

function isExist(listMethod, method)

    for _, v in ipairs(listMethod) do
        if string.lower(v) == string.lower(method) then
            return true
        end
    end
    return false
end


function parseBody(conf)

    local method = string.lower(kong.request.get_method())
    local args = {}



    if method == "get" then
        local query, err = kong.request.get_query()


        if err then
            return {}, {status = 500, message = "not found params"}
        else
            args = query
        end
    elseif method == 'post' then
        local body, err, mimetype = kong.request.get_body()

        if err then
            return {}, {status = 500, message = "not found params"}
        else

            if mimetype == "application/x-www-form-urlencoded" then
                args = body
            elseif mimetype == "application/json" then
                args = json.decode(kong.request.get_raw_body())
            elseif mimetype == "multipart/form-data" then
                args = multipart(kong.request.get_raw_body(), kong.request.get_header("Content-Type")):get_all()
            else
                return {}, {status = 500, message = "not found params"}
            end
        end
    end
    return args, nil
end


return Timing