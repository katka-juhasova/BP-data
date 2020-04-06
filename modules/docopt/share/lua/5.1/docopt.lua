local function is_table(variable)
	return type(variable) == 'table'
end

local function is_number(variable)
	return type(variable) == 'number'
end

local function split_to_words(s)
	return s:gmatch('%S+')
end

local function trim_lines(s)
	return (s:gsub("\n%s*", "\n"):gsub("%s*\n", "\n"))
end 

local function remove_first_line(s)
	return (s:gsub("^.*:.*\n", ""))
end

local function clear_section(section)
	section = remove_first_line(section)
	section = trim_lines(section)
	return section
end

local function split_section_to_lines(section)
	section = clear_section(section)
	return section:gmatch("[^\r\n]+")
end

local function remove_last_empty_line(s)
	return (s:gsub('\n%s*$', ''))
end

local function unify_lines_indentation(s)
	return (section:gsub("\n(%s+)", "\n    "))
end

local function match_to_first_empty_line(s)
	value = s:match('^(.-)\n[ \t]-\n')
	if value == nil then value = s end
	return s
end

local function match_section(s, section_delimiter)
	section = s:match('(' .. section_delimiter .. '%s*.*)')
	section = match_to_first_empty_line(section)
	section = unify_lines_indentation(section)
	section = remove_last_empty_line(section)
	return section
end

local function merge_tables(...)
	result = {}
	for i=1, arg['n'], 1 do
		for key, value in pairs(arg[i]) do
			result[key] = value
		end
	end
	return result
end

local function push_to_table(t, element)
	table.insert(t, table.getn(t) + 1, element)
end

local function resolve_params(params, default_params)
	if params == nill then
		params = {}
	end

	return merge_tables(default_params, params)
end

-- Returns list of arguments given to the program from terminal without program name
local function get_cli_arguments()
	arguments = {}

	for key, value in pairs(_G.arg) do	
		if is_number(key) and key > 0 then
			table.insert(arguments, table.getn(arguments) + 1, value)
		end
	end

	return arguments
end

local function terminate(message)
	print(message)
	os.exit(1)
end

local Rule = {
	_create = function(self)
		rule = {
			name = nil,
			variable = false
		}
		setmetatable(rule, self)
		self.__index = self
		return rule
	end,

	create_from_string = function(self, s)
		rule = self:_create()
		rule.name = s

		if rule.name:find('^<%w+>$') then
			rule.variable = true
		end

		return rule
	end,

	match_argument = function(self, argument)
		if self.variable then
			return argument
		else
			return argument == self.name
		end
	end,

	get_name = function(self)
		return self.name
	end
}

local Route = {
	_create = function(self)
		route = {
			rules = {}
		}
		setmetatable(route, self)
		self.__index = self
		return route
	end,

	parse_doc_to_words = function(self, s)
		words = split_to_words(s)
		words() -- remove first word (name of the program)
		return words
	end,

	create_from_string = function(self, s)
		route = self:_create()

		for word in self:parse_doc_to_words(s) do
			push_to_table(route.rules, Rule:create_from_string(word))
		end

		return route
	end,

	match_arguments = function(self, arguments)
		rule_id = 1

		resolved_arguments = {}

		for key, argument in ipairs(arguments) do
			rule = self.rules[rule_id]

			value = rule:match_argument(argument)
			
			if value ~= nil then			
				resolved_arguments[rule:get_name()] = value
			else
				return
			end

			rule_id = rule_id + 1;
		end

		if rule_id - 1 < table.getn(self.rules) then
			return
		end

		return resolved_arguments
	end
}

local Router = {
	_create = function(self)
		router = {
			routes = {}
		}
		setmetatable(router, self)
		self.__index = self
		return router
	end,

	create_from_string = function(self, section)
		router = self:_create()

		lines = split_section_to_lines(section)

		for line in lines do
			route = Route:create_from_string(line)
			push_to_table(router.routes, route)
		end

		return router
	end,

	match_arguments = function(self, arguments)
		for key, route in pairs(self.routes) do
			resolved_arguments = route:match_arguments(arguments)
			if is_table(resolved_arguments) then
				return resolved_arguments
			end
		end
	end
}

local default_params = {
	argv = get_cli_arguments(),
	help = true,
	version = nil,
	options_first = false
}

function docopt(doc, params)
	params = resolve_params(params, default_params)
	usage_section = match_section(doc, 'Usage:')
	
	router = Router:create_from_string(usage_section)
	resolved_arguments = router:match_arguments(params.argv)

	if resolved_arguments ~= nil then
		return resolved_arguments
	else	
		terminate(usage_section)
	end	
end