-- vim: set noexpandtab :miv --

local is51 = _VERSION == 'Lua 5.1'
local global = _ENV or _G

local function flatten(tab, flat)
	if flat == nil then
		flat = { }
	end
	for key, value in pairs(tab) do
		if type(key) == "number" then
			if type(value) == "table" then
				flatten(value, flat)
			else
				flat[#flat + 1] = value
			end
		else
			if type(value) == "table" then
				flat[key] = table.concat(value, ' ')
			else
				flat[key] = value
			end
		end
	end
	return flat
end

local function inner(_ENV, content, escape)
	if is51 then setfenv(1, _ENV) end
	for i = 1, #content do
		local entry = content[i]
		if type(entry) == 'string' then
			print(escape and escape(entry) or entry)
		elseif type(entry) =='function' then
			entry()
		else
			print(escape and escape(tostring(entry)) or tostring(entry))
		end
	end
end

local language -- Function to create a new output language

local function bind_node_function(_ENV, node_handler)
	if is51 then setfenv(1, _ENV) end
	return function(tagname, ...)
		local arguments = flatten({...})
		local content = {}
		for k, v in ipairs(arguments) do
			content[k] = v
			arguments[k] = nil
		end
		return node_handler(
			_ENV, tagname, arguments,
			#content>0 and function(escape) return inner(_ENV, content, escape) end
		)
	end
end

local function make_environment(node_handler)
	local environment do
		environment = setmetatable({}, {
			__index = function(self, key)
				if global[key] then
					return global[key]
				elseif key == 'escape' then
					return function(...)
						return ...
					end
				else
					return function(...)
						return self.node(key, ...)
					end
				end
			end
		})
	end

	if is51 then
		setfenv(1, environment)
	end
	local _ENV = _ENV and environment

	node = bind_node_function(environment, node_handler)
	return environment
end

local initialize
if is51 then
	function initialize(environment, initializer)
		local e = getfenv(initializer)
		setfenv(initializer, environment)
		initializer(environment)
		setfenv(initializer, e)
		return env
	end
else
	function initialize(environment, initializer)
		initializer(environment)
		return env
	end
end

local function chaininit(language, current)
	current = current or language
	if current.parent then
		chaininit(language, current.parent)
	end
	if current.initializer then
		initialize(language.environment, current.initializer)
	end
	return language
end

local function derive(parent, initializer)
	local derivate = language(parent.node_handler)
	derivate.parent = parent
	derivate.initializer = initializer

	derivate.environment.node = bind_node_function(derivate.environment, derivate.node_handler)
	do local meta = getmetatable(derivate.environment)
		local parent = parent.environment
		local __index = meta.__index
		meta.__index = function(parent, key)
			return rawget(parent, key) or rawget(parent, key) or __index(parent, key)
		end
	end
	setmetatable(derivate, {__index = parent})

	return chaininit(derivate)
end

local function readfile(file)
	file = assert(io.open(file))
	local content = file:read("*a")
	file:close()
	return content
end

local loadlua if is51 then
	loadlua = function(self, code, name, filter)
		if type(code)~='string' then
			local name = debug.getinfo(1, 'n').name or 'loadlua'
			return nil, 'bad argument #1 to '..name..' (got '..type(code)..', expected string)'
		end
		if name == nil then
			name = "xhmoon"
		end
		if filter then
			local err
			code, err = filter(code)
			if type(code)~='string' then
				local name = debug.getinfo(1, 'n').name or 'loadlua'
				return nil, err, 'bad argument #2 to '..name..' (returned '..type(code)..' instead of string)'
			end
		end
		return setfenv(loadstring(code, name), self.environment)
	end
else
	loadlua = function(self, code, name, filter)
		if type(code)~='string' then
			local name = debug.getinfo(1, 'n').name or 'loadlua'
			return nil, 'bad argument #1 to '..name..' (got '..type(code)..', expected string)'
		end
		if name == nil then
			name = "xhmoon"
		end
		if filter then
			local err
			code, err = filter(code) or code
			if type(code)~='string' then
				local name = debug.getinfo(1, 'n').name or 'loadlua'
				return nil, err or 'bad argument #2 to '..name..' (returned '..type(code)..' instead of string)'
			end
		end
		return load(code, name, "bt", self.environment)
	end
end

local loadluafile = function(self, file, filter)
	return self:loadlua(readfile(file), file, filter)
end

function language(node_handler, initializer)
	local environment = make_environment(node_handler)
	if initializer then
		initialize(environment, initializer)
	end
	return {
		initializer = initializer,
		node_handler = node_handler,
		derive = derive,
		loadlua = loadlua,
		loadluafile = loadluafile,
		environment = environment
	}
end

return language
