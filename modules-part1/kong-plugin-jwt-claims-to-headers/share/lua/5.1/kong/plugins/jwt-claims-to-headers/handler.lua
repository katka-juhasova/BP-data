local BasePlugin = require "kong.plugins.base_plugin"
local jwtParser = require "kong.plugins.jwt.jwt_parser"

local JwtClaimsToHeadersHandler = BasePlugin:extend()

-- ensure the priority is lower than the Jwt plugin, which has a priority of 1005
JwtClaimsToHeadersHandler.PRIORITY = 10

-- local functions ------------------------------

--- Retrieve a JWT in a request.
-- Checks for the JWT in URI parameters, then in cookies, and finally
-- in the `Authorization` header.
-- @param conf Plugin configuration
-- @return token JWT token contained in request (can be a table) or nil
-- @return err
local function retrieve_token(conf)
    -- kong.log.debug("@@@@@ Config:")
    -- kong.log.inspect(conf)
    -- kong.log.debug("@@@@@ size is ", table.getn(conf.cookie_names))

    local args = kong.request.get_query()
    if conf.uri_param_names ~= nil then
        for _, v in ipairs(conf.uri_param_names) do
            if args[v] and args[v] ~= "" then
                return args[v]
            end
        end
    end

    if conf.cookie_names ~= nil then
        local var = ngx.var
        for _, v in ipairs(conf.cookie_names) do
            local cookie = var["cookie_" .. v]
            if cookie and cookie ~= "" then
                return cookie
            end
        end
    end

    local authorization_header = kong.request.get_header("authorization")
    if authorization_header then
        local iterator, iter_err = ngx.re.gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
        if not iterator then
            return nil, iter_err
        end

        local m, err = iterator()
        if err then
            return nil, err
        end

        if m and #m > 0 then
            return m[1]
        end
    end
end

local function header_for_claim(claim_name, config)

    -- if the config includes a table, claims_to_headers_table, that specifies a map of claims to headers,
    -- return the header for this claim name.
    -- If a table exists, but there is no mapping for this claim, return nil
    -- Otherwise, return a concatenation of the header_prefix and the key name.
    -- The header is specified in config.header_prefix.

    local header = nil
    local claims_to_headers_table = config.claims_to_headers_table
    local header_prefix = config.header_prefix or defaultHeaderPrefix

    if claims_to_headers_table ~= nil then
        if claims_to_headers_table[claim_name] ~= nil then
            header = claims_to_headers_table[claim_name]
        end
    else
        header = header_prefix .. claim_name
    end

    return header
end

local function claims(jwt, config)

    local jwt_table, err = jwtParser:new(jwt)
    if err ~= nil then
        kong.log.err("Error parsing the jwt: ", err, " jwt: ", jwt)
        return nil, err
    end

    local claims_table = jwt_table["claims"]
    kong.log.debug("Jwt claims:")
    kong.log.inspect(claims_table)

    return claims_table, err
end

function JwtClaimsToHeadersHandler:new()
    JwtClaimsToHeadersHandler.super.new(self, "jwt-claims-to-headers")
end

-- Plugin functions ------------------------------

--- Access
-- If there is a jwt, extract its claims and set a header for each claims, as specified in config parameters
-- If there is no jwt, log an info message and return
-- @param config Plugin configuration
function JwtClaimsToHeadersHandler:access(config)
    JwtClaimsToHeadersHandler.super.access(self)

    local jwt, err = retrieve_token(config)
    if err ~= nil then
        kong.log.err("Error extracting the jwt: ", err, " jwt: ", jwt)
        return
    end

    if jwt == nil then
        kong.log.info("There is no jwt, returning without setting claims to headers")
        return
    end

    kong.log.debug("Jwt is : ", jwt)

    local claims_table, err = claims(jwt, config)
    if err ~= nil then
        kong.log.err("Error extracting claims: ", err, " jwt: ", jwt)
        return
    end

    if claims_table ~= nil then
        for key, value in pairs(claims_table) do
            local header = header_for_claim(key, config)
            if header ~= nil then
                kong.log.debug("Set header: '", header, "' to value: '", value, "'")
                kong.service.request.set_header(header, value)
            end
        end
    end

end

--[[
function JwtClaimsToHeadersHandler:header_filter(config)
    -- kong.response.set_header(name, value)
end
]]


return JwtClaimsToHeadersHandler