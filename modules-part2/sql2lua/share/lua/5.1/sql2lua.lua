-- sql2lua: Generate Lua functions from SQL queries.
-- Copyright 2016 crowl <crowl@mm.st>
-- MIT Licensed.

local lpeg = require "lpeg"
local lustache = require "lustache"

local lower          = lpeg.R("az")
local upper          = lpeg.R("AZ")
local numeral        = lpeg.R("09")
local whitespace     = lpeg.S" \t"
local newline        = lpeg.P"\n" + lpeg.P"\r\n"
local alpha          = lower + upper
local alphanum       = alpha + numeral
local space          = whitespace^1
local blankline      = whitespace^0 * newline
local name_tag       = lpeg.P"name:"
local name           = (lower^1 * (alphanum + lpeg.P"_")^0)^1
local comment_marker = lpeg.P"--"
local line           = (alphanum^1 + lpeg.S".,?<>+-*/=:()_'")^1
local parameter      = lpeg.Cg(lpeg.P":" * lpeg.C((alpha^1 * (alpha + lpeg.P"_")^0)^1))^1 * blankline^-1

local function wrap_param (p)
	return p / function (name) return { param = name } end
end

local function wrap_statement (p)
	return p / function (...) return {...} end
end

local statement_parser = lpeg.P{
	"statement",
	statement = wrap_statement(lpeg.V"string" * (wrap_param(parameter) * lpeg.V"string")^0),
	string    = lpeg.C(space^-1 * ((line - parameter)^1 * space^-1)^0)
}

local function wrap_query (p)
	return p / function (name, statement)
		return {
			name = name,
			parts = statement_parser:match(statement)
		}
	end
end

local function join (a, b)
	return a .. " " .. b
end

local function table_append (t, v)
	t[#t + 1] = v
	return t
end

local queries_parser = lpeg.P{
	"queries",
	queries   = lpeg.Cf(lpeg.Cc({}) * lpeg.V"query"^0, table_append) * -1,
	query     = wrap_query(lpeg.V"name" * lpeg.V"statement"),
	statement = lpeg.Cf(lpeg.V"line"^1, join),
	name      = space^-1 * comment_marker * space^0 * name_tag * space^1 * lpeg.C(name) * space^-1 * newline,
	line      = space^-1 * -comment_marker * (lpeg.C(line) * space^-1)^0 * newline
}

local function template_env (queries)
	return {
		queries = queries,
		params = function (self)
			for _, v in ipairs(self.parts) do
				if type(v) == "table" then return "params" end
			end
			return nil
		end,
		body = function (self)
			local statement = {}
			for _, v in ipairs (self.parts) do
				if type(v) == "table" then
					table.insert(statement, "escape(params." .. v.param .. ")")
				else
					table.insert(statement, "\"" .. v .. "\"")
				end
			end
			return table.concat(statement, " ..\n\t\t")
		end
	}
end

local template = [[
local type = type
local tostring = tostring

local function escape (val)
	local exp_type = type(val)
	if "number" == exp_type then
		return tostring(val)
	elseif "string" == exp_type then
		return "'" .. tostring((val:gsub("'", "''"))) .. "'"
	elseif "boolean" == exp_type then
		return val and "TRUE" or "FALSE"
	else
		return tostring(val)
	end
end

local _M = {}

{{#queries}}
function _M.{{name}} ({{params}})
	return {{&body}}
end

{{/queries}}
return _M
]]

return function (sql)
	local queries = assert(queries_parser:match(sql))
	if not queries then
		return nil, error("invalid SQL input")
	end
	local luastring = lustache:render(template, template_env(queries))
	return assert(loadstring(luastring))()
end
