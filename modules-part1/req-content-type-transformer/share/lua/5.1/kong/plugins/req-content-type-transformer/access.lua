-- Third Party Libs
local stringy = require "stringy"
local multipart = require "multipart"
local cjson = require "cjson"

-- Openresty Based Libs
local string_find = string.find
local string_len = string.len
local table_maxn = table.maxn
local req_clear_header = ngx.req.clear_header
local req_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local req_set_uri_args = ngx.req.set_uri_args
local req_get_uri_args = ngx.req.get_uri_args
local req_get_body_data = ngx.req.get_body_data
local req_set_body_data = ngx.req.set_body_data
local req_read_body = ngx.req.read_body
local encode_args = ngx.encode_args
local ngx_decode_args = ngx.decode_args

-- Lua Based Libs
local unpack = unpack
local pcall = pcall

local _M = {}

local CONTENT_LENGTH = "content-length"
local CONTENT_TYPE = "content-type"
-- Different HTTP POST TYPE
local JSON, MULTI, ENCODED = "json", "multi_part", "form_encoded"
local HTTP_METHOD = {
  POST = "POST",
  GET = "GET"
}

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end

local function decode_args(body)
  if body then
    return ngx_decode_args(body)
  end
  return {}
end

local function get_content_type(content_type)
  if content_type == nil then
    return
  end
  if string_find(content_type:lower(), "application/json", nil, true) then
    return JSON
  elseif string_find(content_type:lower(), "multipart/form-data", nil, true) then
    return MULTI
  elseif string_find(content_type:lower(), "application/x-www-form-urlencoded", nil, true) then
    return ENCODED
  end
end

local function transform_json_to_form(body, content_length)
  local content_length = (body and string_len(body)) or 0
  local parameters = parse_json(body)
  if parameters == nil and content_length > 0 then return false, nil end -- Couldn't modify body

  req_set_header(CONTENT_TYPE, "application/x-www-form-urlencoded")
  return true, encode_args(parameters)
end

local function transform_form_to_json(body, content_length)
  local content_length = (body and string_len(body)) or 0
  local parameters = decode_args(body)
  if parameters == nil and content_length > 0 then return false, nil end -- Couldn't modify body

  req_set_header(CONTENT_TYPE, "application/x-www-form-urlencoded")
  return true, cjson.encode(parameters)
end

local function req_transform(conf)
  local content_type_value = req_get_headers(0)[CONTENT_TYPE]
  local content_type = get_content_type(content_type_value)
  if content_type == nil or conf.transformer == nil then
    return -- POST body only supports three basic types.
  end

  req_read_body()
  local body = req_get_body_data()
  local is_body_transformed = false
  local content_length = (body and string_len(body)) or 0
  -- Call req_read_body to read the request body first
  if "JSON_TO_FORM" == conf.transformer and content_type == JSON then
    is_body_transformed, body = transform_json_to_form(body, content_length)
  end

  if "FORM_TO_JSON" == conf.transformer and content_type == FORM then
    is_body_transformed, body = transform_form_to_json(body, content_length)
  end

  if is_body_transformed then
    req_set_body_data(body)
    req_set_header(CONTENT_LENGTH, string_len(body))
  end
end

-- This method would transfer head attribute to body or querystring based on request type
-- Only supports POST & GET method
function _M.execute(conf)
  local request_method = ngx.req.get_method()
  if HTTP_METHOD.POST == request_method then
    req_transform(conf)
  end
end

return _M
