---------------------------------------------------------------------------------------------------------
-- Distributed task helper for Harpseal
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.10
--
-- Note:
--	*) a interface of task define helper.
--	*) encode/decode fields for local supported object, from/to JSON compatible field types.
---------------------------------------------------------------------------------------------------------
local BASE64 = require('lib.BASE64')
local BASE64_encode = BASE64.to_base64
local BASE64_decode = BASE64.from_base64

local JSON = require('lib.JSON')
local JSON_decode = function(...) return JSON:decode(...) end
local JSON_encode = function(...) return JSON:encode_pretty(...) end

local typeDefaults = {
	["data"] =		{ subType = 'string', encodeType = 'utf8' },
	["string"] =	{ subType = nil, encodeType = 'utf8' },
	["script"] =	{ subType = nil, encodeType = '*' },
	["lua"] =		{ subType = nil, encodeType = '*' },
}
local nothing = function(s) return s end
local decodeMethods = {
	["base64"] = BASE64_decode,
	["*"] = nothing,
	["utf8"] = nothing,	-- TODO: utf8 support
}

local function prefixParse(str)
	local found, _, body = string.find(str, ':([^:]*)$') -- find tailed ':'
	local prefix = string.sub(str, 1, found or 0)
	if prefix == "" then return true, str end  -- none prefix, result valid
	if prefix == ":" then return false, "Invalid prefix" end

	local prefixs = {}
	for p in string.gmatch(prefix, '([^:]+):') do prefixs[#prefixs+1] = p end

	local mid = math.ceil(#prefixs / 2)
	local t = prefixs[mid]
	local default = typeDefaults[t]
	-- try resolve encodeType
	if math.mod(#prefixs, 2) > 0 then -- odd-numbered
		if not default then return false, "Can't resolve default decode type" end
		table.insert(prefixs, mid+1, default.encodeType)
	end

	-- try resolve subType(with encodeType for subType)
	while default and default.subType do
		mid = mid + 1
		t = default.subType
		default = typeDefaults[t]
		if default then
			if not default.encodeType then break end
			table.insert(prefixs, mid, default.encodeType)
			table.insert(prefixs, mid, t)
		end
	end

	-- decode all and return
	for i = mid+1, #prefixs do
		local method = decodeMethods[prefixs[i]]
		if not method then return false, "Can't decode with method: " .. prefixs[i] end
		body = method(body)
	end

	return table.concat(prefixs, ':', 1, mid), body
end

-- encode to json compatible object
local function encode_task_fields(obj)
	local taskDef, jsonTypes = {}, {['string']=true, ['boolean']=true, ['number']=true, ['table']=true}
	for key, result in pairs(obj) do
		if type(key) ~= 'string' then
			print('Unsupported key type in taskObjet, key type: ' .. type(key))
		else
			local t = type(result)
			if t == 'table' then
				if #result > 0 then
					local arr = {}
					for i, t in ipairs(result) do
						arr[i] = encode_task_fields(t)
					end
					taskDef[key] = arr
				else
					taskDef[key] = encode_task_fields(result)
				end
			elseif t == 'function' then
				local str = string.dump(result)
				taskDef[key] = 'script:lua:base64:' .. BASE64_encode(str)
			elseif jsonTypes[t] then
				taskDef[key] = result
			else
				print('Unsupported data type in taskObjet, key: ' .. key .. ', result type: ' .. t)
			end
		end
	end
	return taskDef
end

-- decode fields from object (the object from standard taskDef JSON text)
local function decode_task_fields(taskDef)
	for name, value in pairs(taskDef) do
		local t = type(value)
		if t == 'table' then
			-- array compatible
			decode_task_fields(taskDef[name])
		elseif t == 'string' then
			-- performance: try hard match for top prefix
			if string.match(value, '^data:') or string.match(value, '^script:') then
				local prefix, result = prefixParse(value)
				if not prefix then
					error(result)
				elseif prefix == 'data:string' then
					taskDef[name] = result
				elseif prefix == 'script:lua' then
					taskDef[name] = loadstring(result)
				else
					taskDef[name] = value
				end
			else
				taskDef[name] = value
			end
		end
	end
	return taskDef
end

return {
	version = '1.1',

	-- DONT Modify These Constants !
	TASK_BLANK = "task:99914b932bd37a50b983c5e7c90ae93b",	-- {}
	TASK_SELF = "task:6934703c3b4d0714b25f4b5e6148c11a",		-- {"promised":"return self"}
	TASK_RESOURCE = "task:01d13608d51c57d757ce4c630952f49a",	-- {"promised":"return resource"}
	LOGGER = "!",

	encode = function(task)
		return JSON_encode(encode_task_fields(task))
	end,

	decode = function(taskDef)
		return decode_task_fields(JSON_decode(taskDef))
	end,

	run = function(_, task, args)
		return { run = task, arguments = args }
	end,

	map = function(_, distributionScope, task, args)
		return { map = task, scope = distributionScope, arguments = args}
	end,

	require = function(resId)
		return this.run(this.TASK_RESOURCE, resId)
	end,

	reduce = function(self, distributionScope, task, args, reduce)
		if not reduce then
			return self:run(args, self:map(distributionScope, task)) -- args as reduce
		else
			return self:run(reduce, self:map(distributionScope, task, args))
		end
	end,

	daemon = function(self, distributionScope, task, daemon, deamonArgs)
		return self:map(distributionScope, task, self:run(daemon, deamonArgs))
	end,
}