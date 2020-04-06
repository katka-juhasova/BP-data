---------------------------------------------------------------------------------------------------------
-- Distributed http client helper for Harpseal
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.10
--
-- Note:
--	*) a interface of distributed http client requests
---------------------------------------------------------------------------------------------------------
local Promise = require('lib.Promise')
local copas = require('copas')
local http = require('socket.http')
local limited =  require('copas.limit')

local max_connections = 5
local limited_pool = limited.new(max_connections)

local JSON = require('lib.JSON')
local JSON_encode = function(...) return JSON:encode_pretty(...) end

----------------------------------------------------------------------------------------------------------------
-- http client
----------------------------------------------------------------------------------------------------------------
local function ignore(ok, code, headers)
	-- print('ERROR -->', ok, code, JSON_encode(headers))
end

local function parseParaments(url, options, callback)
	local t, defaultOptions = type(url), {method = 'GET'}
	local callback = callback or ignore
	if t == 'string' then
		if type(options) == 'function' then
			return setmetatable({url=url}, {__index=defaultOptions}), options 		-- <options> as callback
		elseif type(options) == 'table' then
			options = options.method and options or setmetatable(defaultOptions, {__index=options})
			return setmetatable({url=url}, {__index=options}), callback
		else
			return setmetatable({url=url}, {__index=defaultOptions}), callback		-- ignore <options>
		end
	elseif t == 'table' then
		return setmetatable(url.method and url or defaultOptions, {__index=url}),	-- <url> as request object
			type(options) == 'function' and options or ignore						-- <options> as callback
	else
		error('parse request paraments error')
	end
end

local function http_request2(req, callback)
	local t = {}
	req.sink = ltn12.sink.table(t)
	local ok, code, headers = http.request(req)		-- {result, code, headers, status} from <http.lua>
	callback(ok, code, {headers = headers}, next(t) and table.concat(t) or nil)
end

-- synchronous request
local function http_request(...)
	return http_request2(parseParaments(...))
end

-- promised parallel asynchronous request
local function promised_request(req)
	-- NOTE: cant catch/reject exception in http_request()/http_request2() and the callback
	return Promise.new(function(resolve, reject)
		limited_pool:addthread(http_request2, parseParaments(req, function(ok, code, resp, body)
			if ok then
				-- with status >= 200 (ngx.HTTP_OK) and status < 300 (ngx.HTTP_SPECIAL_RESPONSE) for successful quits
				--	*) see: https://www.nginx.com/resources/wiki/modules/lua/#ngx-exit
				local status = tonumber(code) or 200
				ok = status >= 200 and status < 300
			end
			-- response schema @see: https://www.nginx.com/resources/wiki/modules/lua/#ngx-location-capture
			return (ok and resolve or reject)({status = code, body = body, header = resp.headers})
		end))
	end)
end

----------------------------------------------------------------------------------------------------------------
-- request_stringify()
--	@see: https://nodejs.org/api/querystring.html#querystring_querystring_stringify_obj_sep_eq_options
--	@see: http://lua-users.org/wiki/StringRecipes
----------------------------------------------------------------------------------------------------------------
local function url_encode(str)
	local ok, str = pcall(tostring, str)
	if not ok then return '' end
	str = string.gsub(str, "\n", "\r\n")
	str = string.gsub(str, "([^%w %-%_%.%~])",
		function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = string.gsub(str, " ", "+")
	return str
end

local function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

local function querystring_stringify(obj)
	local fields = {}
	for key, value in pairs(obj) do
		local ok, str = pcall(tostring, value)
		table.insert(fields, url_encode(key) .. '=' .. url_encode(value))
	end
	return table.concat(fields, '&')
end

local function querystring_parse(str)
	local obj, exist, value = {}
	for name, _, param in string.gmatch(str, '([^=&]+)(=?([^&]*))&?') do
		name, param = url_decode(name), url_decode(param)
		exist, value = obj[name], param and (tonumber(param) or param) or true
		if exist then
			if type(exist) ~= 'table' then
				obj[name] = {exist, value}
			else
				exist[#exist+1] = value
			end
		else
			obj[name] = value
		end
	end
	return obj
end

----------------------------------------------------------------------------------------------------------------
-- Utils
----------------------------------------------------------------------------------------------------------------

-- check paraments separator for url
local function find_separator(url)
	return string.find(url, '?') and '&' or '?'
end

-- asQuery(obj)
local function asQuery(obj)
	return ((not (obj.method or obj.data)) and querystring_stringify(obj)  -- default is simple GET request
		or ((obj.method and (string.upper(obj.method) == 'GET')) and querystring_stringify(obj.vars or {}) -- force as GET request
		or obj))
end

-- asQueryString(obj)
local function asQueryString(args)
	return type(args) == 'string' and args or querystring_stringify(args)
end

-- asRequest(query)
local function asRequest(query)
	local t = type(query)
	if t == 'nil' or t == 'string' then
		return query
	elseif t == 'table' then
		local request_string, request_options = false, query
		if query.args then
			if not query.data then
				local headers = query.headers or {}
				if not query.headers then query.headers = headers end
				if not headers["Content-Type"] then -- reset to default
					headers["Content-Type"] = "application/x-www-form-urlencoded"
				end

				if string.lower(headers["Content-Type"]) == "application/json" then
					query.data = JSON_encode(type(query.args) == 'table' and query.args
						or querystring_parse(tostring(query.args)))
				else
					query.data = asQueryString(query.args)
				end
			else
				-- send original request, <params> append to url
				request_string = asQueryString(query.args)
			end
			query.args = ""
			query.method = "POST"
		end
		return request_string, request_options
	else
		error('unknow distributed request type')
	end
end

----------------------------------------------------------------------------------------------------------------
-- distributed_request()
----------------------------------------------------------------------------------------------------------------

-- need promise three arguments as arrResult
local function distributed_request(arrResult)
	local URLs, taskId, args = unpack(arrResult)
	local query =  (type(args) == 'table') and asQuery(args) or (args ~= nil and tostring(args) or nil)
	local requests, request_string, request_options = {}, asRequest(query)
	for _, url in ipairs(URLs) do
		if request_string then
			url = url .. taskId .. find_separator(url) .. request_string
		else
			url = url .. taskId
		end
		table.insert(requests, promised_request(url, request_options))
	end
	return Promise.all(requests)
end

return {
	distributed_request = distributed_request,
	-- request_stringify = querystring_stringify,
	start = copas.loop,
}