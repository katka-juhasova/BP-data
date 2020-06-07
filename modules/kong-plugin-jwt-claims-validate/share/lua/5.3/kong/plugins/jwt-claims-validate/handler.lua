local json = require "cjson"
local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local req_set_header = ngx.req.set_header
local ngx_re_gmatch = ngx.re.gmatch

local JwtClaimsValidateHandler = BasePlugin:extend()
JwtClaimsValidateHandler.PRIORITY = 850

local function retrieve_token(request, conf)
  local uri_parameters = request.get_uri_args()

	for _, v in ipairs(conf.uri_param_names) do
    if uri_parameters[v] then
      return uri_parameters[v]
    end
  end

  local authorization_header = request.get_headers()["authorization"]
  if authorization_header then
    local iterator, iter_err = ngx_re_gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
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

local function joinArray(delimiter, list)
  local len = #list
  if len == 0 then
    return ""
  end
  local string = list[1]
  for i = 2, len do
    string = string .. delimiter .. list[i]
  end
  return string
end

local function splitArray(delimiter, text)
  local list = {}; local pos = 1
  if string.find("", delimiter, 1) then
    -- We'll look at error handling later!
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    print (first, last)
    if first then
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end

local function trim(str)
  return (str:gsub("^%s*(.-)%s*$", "%1"))
end

local function compare_value(v1, v2)
  if not (type(v2) == "string") then
	return v1 == v2
  end

  for value in string.gmatch(v2, '([^,]+)') do
    if v1 == trim(value) then
      return true
    end
  end
  return false
end

-- local function has_value (tab, val)
-- 	for index, value in ipairs(tab) do
-- 		if value == val then
-- 				return true
-- 		end
-- 	end

-- 	return false
-- end

local function contains_value(claim_req_value, claim_conf_value)
	-- claim_req_value is the value of the claim in request, claim_conf_value is the configured value
	if type(claim_req_value) == "table" then
		-- if the claims in request is array/table, we change it to string by join elements by " "
		claim_req_value = joinArray(" ", claim_req_value)
	end


	if type(claim_conf_value) == "table" then
		-- if the configured claims is array/table, the claim in request has to contain all the elements in the configured claims
		for _, v in ipairs(claim_conf_value) do
			-- ngx.log(ngx.DEBUG, "configured claim (array) \"", v, "\", request claim: ", claim_req_value)
			if not type(claim_req_value) == "string" then
				-- request claims are not string, we only accept string if configured claim is array
				return false
			elseif not string.find( claim_req_value, v, 1, true ) then
					return false
			end
		end
		return true
	end

  return compare_value(claim_req_value, claim_conf_value)
end

-- local function contains_value(claim_key, claim_value)
--   if type(claim_key) == "table" then
--     for _, v in ipairs(claim_key) do
--       if compare_value(v, claim_value) then
--         return true
--       end
--     end
--   end
--   return compare_value(claim_key, claim_value)
-- end

function JwtClaimsValidateHandler:new()
  JwtClaimsValidateHandler.super.new(self, "jwt-claims-headers")
end

function JwtClaimsValidateHandler:access(conf)
  JwtClaimsValidateHandler.super.access(self)
  local continue_on_error = conf.continue_on_error

  local token, err = retrieve_token(ngx.req, conf)
  if err and not continue_on_error then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  if not token and not continue_on_error then
    return responses.send_HTTP_UNAUTHORIZED()
  end

  local jwt, err = jwt_decoder:new(token)
  if err and not continue_on_error then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR()
  end

	local claims = jwt.claims
	-- local scopes = claims["scope"]
	for claim_key,claim_value in pairs(conf.claims) do



		-- -- if claim_key == "scope" then
		-- if type(claim_value) == "table" then
		-- 	-- local reqScope = claims[claim_key]
		-- 	ngx.log(ngx.DEBUG, "json.encode(claims) \"", json.encode(claims), "\"; claim_key: \"", claim_key, "\"; type of aud: ", type(claims["aud"]), ", type of https://mlib.visualid.com/roles: ", type(claims["https://mlib.visualid.com/roles"]))
		-- 	for _, val in ipairs(claim_value) do
		-- 		ngx.log(ngx.DEBUG, "configured scope \"", val, "\"")
		-- 		if not string.find( claims[claim_key], val, 1, true ) then
		-- 			return responses.send_HTTP_UNAUTHORIZED("Access Token has invalid claim value for '"..claim_key.."'")
		-- 		end
		-- 	end
		-- else
		if claims[claim_key] == nil or contains_value( claims[claim_key], claim_value ) == false then
			return responses.send_HTTP_UNAUTHORIZED("Access Token has invalid claim value for '"..claim_key.."'")
		end
		-- end
	end

	-- Add claims to headers to upstream server
	-- if claims ~= nil then
	req_set_header("x-jwt-claims", json.encode(claims))
	-- end
end

return JwtClaimsValidateHandler
