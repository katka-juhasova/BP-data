local utils = require "kong.tools.utils"
local stringy = require "stringy"
local dkjson = require ("dkjson")

local BodyFilter = {}

-----------------------
-- Utility functions --
-----------------------
local function to_json(body)
	local status, res = pcall(dkjson.decode, body)
	if status then
		return res
	end

	return nil
end

local function remove_ending_slash(url)
	local len = string.len(url)
	local char = string.sub(url, len, len)
	if char == "/" then
		return string.sub(url, 0, len - 1)
	end

	return url
end

local function escape_pattern(pattern)
	local matches =
	{
		["^"] = "%^";
		["$"] = "%$";
		["("] = "%(";
		[")"] = "%)";
		["%"] = "%%";
		["."] = "%.";
		["["] = "%[";
		["]"] = "%]";
		["*"] = "%*";
		["+"] = "%+";
		["-"] = "%-";
		["?"] = "%?";
	}

	return string.gsub(pattern, ".", matches)
end

local function escape_replacement(replacement)
	return string.gsub(replacement, "[%%]", "%%%%")
end

local function replace_url(json,upstream_url,downstream_url)
	rReplace(nil,nil,json,nil,upstream_url,downstream_url)
	return json
end

function rReplace(s, k, v, l,upstream_url,downstream_url) -- recursive Replace (structure, limit, up, down)
l = (l) or 100; i = i or "";	-- default item limit, indent string
if (l<1) then ngx.log(ngx.DEBUG,"ERROR: Item limit reached."); return l-1 end; -- stop condition
local ts = type(v); -- value type
if (ts ~= "table") then
	ngx.log(ngx.DEBUG,v)
	if (ts == "string") then
		s[k] = string.gsub(v,upstream_url,downstream_url)
		ngx.log(ngx.DEBUG,"replaced: " .. v)
	end
	return l-1
end
for k,s in pairs(v) do
	l = rReplace(v, k, s, l,upstream_url,downstream_url); -- recursive step
	if (l < 0) then break end
end
return l
end

---------------------------
-- Filter implementation --
---------------------------
function BodyFilter.execute(body, upstream_url, downstream_url)
	if upstream_url and downstream_url then
		local json_body = to_json(body)
		if json_body then
			return dkjson.encode(replace_url(json_body, remove_ending_slash(escape_pattern(upstream_url)), remove_ending_slash(escape_replacement(downstream_url))), { indent = true })
		end
	end

	return body
end

return BodyFilter 
