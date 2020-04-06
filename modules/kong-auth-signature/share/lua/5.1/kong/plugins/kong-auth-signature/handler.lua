local BasePlugin = require "kong.plugins.base_plugin"
local constants = require "kong.constants"
local multipart = require "multipart"
local json = require "json"
local cjson = require "cjson.safe"
local resty_sha256 = require "resty.sha256"

local Auth = BasePlugin:extend()
local kong = kong
local ipairs = ipairs
local pairs = pairs
local string = string
local type = type
local ngx = ngx
local concat = table.concat
local insert = table.insert
local find = string.find
local type = type
local sub = string.sub
local gsub = string.gsub
local match = string.match
local lower = string.lower

Auth.VERSION = "0.1.0-4"
Auth.PRIORITY = 999

local CHAR_TO_HEX = {};
for i = 0, 255 do
  local char = string.char(i)
  local hex = string.format("%02x", i)
  CHAR_TO_HEX[char] = hex
end

function Auth:new()
    Auth.super.new(self, "kong-auth-signature")
end


local function hex_encode(str)
    return (str:gsub(".", CHAR_TO_HEX))
end

local function sha256Signature(msg)
    local sha256 = resty_sha256:new()
    sha256:update(msg)
    return hex_encode(sha256:final())
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
    elseif method == "post" then
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


function sortKeySignature( args, conf )
    local index = {}
    local result = {}

    for _,v in pairs(args) do

        if string.lower(conf.body_key) ~= string.lower(_) then
            table.insert(index, _)
        end
    end

    table.sort(index)


    for _, v in pairs(index) do
        table.insert( result, args[v] )
    end

    return result
end

function createSignatureAuth(key, args, conf)

    local queryString = ""
    local sargs = sortKeySignature(args, conf)
    for _, v in pairs(sargs) do

        queryString = queryString .. v
    end

    local method = string.lower(kong.request.get_method())
    local signature = tostring(sha256Signature(queryString .. conf.secret_signature))
    args["signature"] = signature

    if method == "get" then

        kong.service.request.set_query(args)
    elseif method == "post" then

        kong.service.request.set_body(args)
    end

    kong.log("queryString", " | ", queryString, " | ", "signature", " | ", signature)
    return sha256Signature(queryString..key)
end

local function read_json_body(body)
    if body then
      return cjson.decode(body)
    end
end

function is_json_body(content_type)
    return content_type and find(lower(content_type), "application/json", nil, true)
end

function transform_json_body_response(conf, buffered_data)
    local json_body = read_json_body(buffered_data)
    if json_body == nil then
      return cjson.encode({
            success = false,
            error = {
                code = 400,
                message = "400 Bad Request"
            }
        })
    end


    return buffered_data
end


function doAuthenticationSignature(conf)

    if not conf.header_key or not conf.body_key then
        return false, { code = 400, status = 400, message = "400 Bad Request"}
    end

    local api_key = kong.request.get_header(conf.header_key)
    local body, err = parseBody(conf)

    if err or not api_key or not body[conf.body_key] then
        return false, { code = 400, status = 400, message = "400 Bad Request"}
    end

    if not conf.api_key_1 and not conf.api_key_2 and not conf.api_key_3 and not conf.api_key_4 and not conf.api_key_5 then
        return false, { code = 400, status = 400, message = "400 Bad Request" }
    end

    local secret_key = ""
    if conf.api_key_2 == api_key then
        secret_key = conf.secret_key_2
    elseif conf.api_key_1 == api_key then
        secret_key = conf.secret_key_1
    elseif conf.api_key_3 == api_key then
        secret_key = conf.secret_key_3
    elseif conf.api_key_4 == api_key then
        secret_key = conf.secret_key_4
    elseif conf.api_key_5 == api_key then
        secret_key = conf.secret_key_5
    else
        return false, { code = 400, status = 400, message = "400 Bad Request" }
    end

    local signature = body.signature
    local verify_sign = createSignatureAuth(secret_key, body, conf)

    kong.log("verify_sign", " | ", verify_sign, " | ", signature)
    if verify_sign ~= signature then
        return false, { code = 400,  status = 400, message = "Chữ ký bảo mật không đúng" }
    end

    return true, nil
end

function Auth:access(conf)

    Auth.super.access(self)


    local ok, err = doAuthenticationSignature(conf)


    if err ~= nil then

        kong.log("check_signature", " | ", err.message)

        return kong.response.exit(err.status, {
            message = err.message,
            status = err.code
        })
    end


end


function Auth:header_filter(conf)
    Auth.super.header_filter(self)

    kong.response.clear_header("Content-Length")
end

function Auth:body_filter(conf)
    Auth.super.body_filter(self)

    if is_json_body(kong.response.get_header("Content-Type")) then
        local ctx = ngx.ctx
        local chunk, eof = ngx.arg[1], ngx.arg[2]

        ctx.rt_body_chunks = ctx.rt_body_chunks or {}
        ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

        if eof then
          local chunks = concat(ctx.rt_body_chunks)
          local body = transform_json_body_response(conf, chunks)

          kong.log("chunk_response", chunks)
          ngx.arg[1] = body or chunks

        else
          ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
          ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1
          ngx.arg[1] = nil
        end
    end

end



return Auth