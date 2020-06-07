---------------------------------------------------------------------
-- Compose SQL statements.
--
-- @class module
-- @name dado.sql
-- @release $Id: sql.lua,v 1.39 2017/04/05 19:14:08 tomas Exp $
---------------------------------------------------------------------

local string = require"string"
local gsub, strfind, strformat = string.gsub, string.find, string.format
local table = require"table.extra"
local tabfullconcat, tabtwostr = table.fullconcat, table.twostr
local tonumber, type = tonumber, type

---------------------------------------------------------------------
-- Escape a character or a character class in a string.
-- It also removes character with codes < 32 (except \t (\9), \n (\10)
--	and \r (\13)).
-- @class function
-- @name escape
-- @param s String to be processed.
-- @return String or nil if no string was given.
---------------------------------------------------------------------
local function escape (s)
	if not s then return end
	s = gsub (s, "[%z\1\2\3\4\5\6\7\8\11\12\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]", "")
	s = gsub (s, "'", "''")
	return s
end

---------------------------------------------------------------------
-- Quote a value to be included in an SQL statement.
-- The exception is when the string is surrounded by balanced "(())";
-- in this case it won't be quoted.
-- @class function
-- @name quote
-- @param s String or number or boolean.
-- @return String with quoted value.
---------------------------------------------------------------------
local function quote (s)
	local ts = type(s)
	if ts == "number" or ts == "boolean" then
		return strformat ("((%s))", s)

	elseif ts == "string"
		and s:match"^%b()$" and s:sub(2, -2):match"^%b()$" then
		return s
	else
		return "'"..escape (s).."'"
	end
end

---------------------------------------------------------------------
-- Quote all values associated with the integer keys in a table and
-- concat them on a string, separated by a comma (,).
-- This function is particularly useful to produce expressions for the IN
-- operator.
-- @class function
-- @name quotedconcat
-- @param tab Table with the sequence of values.
-- @return String in the for of a comma separated values.
---------------------------------------------------------------------
local function quotedconcat (tab)
	local _, r = tabtwostr (tab, nil, ',', nil, quote)
	return r
end

---------------------------------------------------------------------
-- Composes simple (almost trivial) SQL AND-expressions.
-- There is no "magic" in this funcion, except that it 'quotes' the
--	values.
-- Hence, for expressions which have any operator other than '=',
--	you should write them explicitly.
-- There is no OR-expression equivalent function (I don't know how to
--	express it conveniently in Lua).
-- @class function
-- @name AND
-- @param tab Table with key-value pairs representing equalities.
-- @return String with the resulting expression.
---------------------------------------------------------------------
local function AND (tab)
	return tabfullconcat (tab, "=", " AND ", nil, quote)
end

---------------------------------------------------------------------
-- Checks if the argument is an integer.
-- Use this function to check whether a value can be used as a
--	database integer key.
-- @class function
-- @name isinteger
-- @param id String with the key to check.
-- @return Boolean or Number (any number can be considered as true) or nil.
---------------------------------------------------------------------
local function isinteger (id)
	local tid = type(id)
	if tid == "string" then
		return id:match"^%s*%-?%d+%s*$"
	else
		return tid == "number"
	end
end

---------------------------------------------------------------------
-- Builds a string with a SELECT command.
-- The existing arguments will be concatenated together to form the
-- SQL statement.
-- The string "select " is added as a prefix.
-- If the tabname is given, the string " from " is added as a prefix.
-- If the cond is given, the string " where " is added as a prefix.
-- @class function
-- @name select
-- @param columns String with columns list.
-- @param tabname String with table name (optional).
-- @param cond String with where-clause (optional).
-- @param extra String with extra SQL text (optional).
-- @return String with SELECT command.
---------------------------------------------------------------------
local function select (columns, tabname, cond, extra)
	tabname  = tabname and (" from "..tabname) or ""
	cond     = cond and (" where "..cond) or ""
	extra    = extra and (" "..extra) or ""
	return strformat ("select %s%s%s%s", columns, tabname, cond, extra)
end

---------------------------------------------------------------------
-- Builds a string with a SELECT command to be inserted into another
-- SQL query.
-- @class function
-- @name subselect
-- @param columns String with columns list.
-- @param tabname String with table name.
-- @param cond String with where-clause (and following SQL text).
-- @param extra String with extra SQL text.
-- @return String with SELECT command.
---------------------------------------------------------------------
local function subselect (columns, tabname, cond, extra)
	return "(("..select (columns, tabname, cond, extra).."))"
end

---------------------------------------------------------------------
-- Builds a string with an INSERT command.
-- @class function
-- @name insert
-- @param tabname String with table name or with the SQL text that
--	follows the "insert into" prefix.
-- @param contents Table of elements to be inserted (optional).
-- @return String with INSERT command.
---------------------------------------------------------------------
local function insert (tabname, contents)
	if contents then
		return strformat ("insert into %s (%s) values (%s)",
			tabname, tabtwostr (contents, ',', ',', nil, quote))
	else
		return strformat ("insert into %s", tabname)
	end
end

---------------------------------------------------------------------
-- Builds a string with an UPDATE command.
-- @class function
-- @name update
-- @param tabname String with table name.
-- @param contents Table of elements to be updated.
-- @param cond String with where-clause (and following SQL text).
-- @return String with UPDATE command.
---------------------------------------------------------------------
local function update (tabname, contents, cond)
	cond = cond and (" where "..cond) or ""
	local set = contents
		and " set "..tabfullconcat (contents, '=', ',', nil, quote)
		or ""
	return strformat ("update %s%s%s", tabname, set, cond)
end

---------------------------------------------------------------------
-- Builds a string with a DELETE command.
-- @class function
-- @name delete
-- @param tabname String with table name.
-- @param cond String with where-clause (and following SQL text).
-- @return String with DELETE command.
---------------------------------------------------------------------
local function delete (tabname, cond)
	cond = cond and (" where "..cond) or ""
	return strformat ("delete from %s%s", tabname, cond)
end

--------------------------------------------------------------------------------
return {
	_COPYRIGHT = "Copyright (C) 2008-2017 PUC-Rio",
	_DESCRIPTION = "SQL is a collection of functions to create SQL statements",
	_VERSION = "Dado SQL 1.8.3",

	quote = quote,
	quotedconcat = quotedconcat,
	escape = escape,
	AND = AND,
	isinteger = isinteger,

	select = select,
	subselect = subselect,
	insert = insert,
	update = update,
	delete = delete,
}
