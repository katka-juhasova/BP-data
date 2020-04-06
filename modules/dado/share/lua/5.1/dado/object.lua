---------------------------------------------------------------------------
-- Database Object.
-- Offers a way to create objects that are associated to database tables.
-- There are some special attributes:
--	db_fields = table (record) that indicates which attributes should
--		be loaded from the database
--	table_name = string with the name of the database table
--	key_name = string with the name of the key attribute/field
--
-- @class module
-- @name dado.object
-- @release $Id: object.lua,v 1.24 2017/04/05 19:14:08 tomas Exp $
---------------------------------------------------------------------------

local ipairs, pairs, rawget, rawset, setmetatable, type = ipairs, pairs, rawget, rawset, setmetatable, type
local sql = require"dado.sql"
local sqlquote, sqlselect = sql.quote, sql.select
local strformat = require"string".format
local concat = require"table".concat

--
-- Tries to create an expression with the given table of keys.
-- @param keys Table with strings with the names of the keys.
-- @return String with the SQL condition.
--
local function build_expression (self, keys)
	local where = {}
	for i, key_name in ipairs (keys) do
		local k = rawget (self, key_name)
		if not k then
			return nil
		end
		where[i] = strformat ("%s = %s", key_name, sqlquote (k))
	end
	return concat (where, " AND ")
end

--
-- Creates an SQL condition which identifies the record.
-- @return String with the SQL text.
--
local function db_identification (self)
	local cond = build_expression (self, self.key_name)
	if cond then
		return cond
	end
	for i, key in ipairs (self.alternate_keys) do
		cond = build_expression (self, key)
		if cond then
			return cond
		end
	end
end

--
-- Builds a list of database fields which are automatically loaded by
-- the object.
--
local function db_fields_list (self)
	local r = {}
	for col, val in pairs (self.db_fields) do
		if val == true then
			r[#r+1] = col
		end
	end
	return concat (r, ',')
end

--
-- Loads attributes from the database.
-- All attributes associated to database fields are retrieved by once.
-- @param attr String with the value of the attribute (optional).
-- @return The value of the attribute or nil (if there is no attribute).
--
local function db_load (self, attr)
	-- Loads all attributes from the database
	local stmt = sqlselect (db_fields_list(self), self.table_name,
		self:db_identification ())
	local cur = self.__dado:assertexec (stmt)
	self.loaded = cur:fetch (self, "a")
	cur:close ()
	-- avoid infinite recursion loop if attribute is NULL at the database
	return attr and rawget (self, attr)
end

--
-- Creates a metatable for the given class.
--
local mt = {
	__index = function (self, attr)
		local res
		-- attributes from database
		if attr ~= "db_fields" and self.db_fields then
			local load = self.db_fields[attr]
			if type(load) == "function" then
				res = load(self, attr) -- Customized way to load value
			elseif load == true then
				res = db_load (self, attr) -- Default way to load value
			end
		end
		-- inherit from class
		if not res and self.__class then
			res = self.__class[attr]
		end
		-- stores the inherited or fetched value in the object
		rawset (self, attr, res)
		return res
	end,
}

---------------------------------------------------------------------------
-- Creates a new object.
-- @class function
-- @name new
-- @param class Table representing the class of the object.
-- @param dado Dado connection.
-- @param o Table representing the object (optional).
-- @return Table representing the object.
---------------------------------------------------------------------------
local function new (class, dado, o)
	o = o or {}
	o.__class = class
	o.__dado = dado
	setmetatable(o, mt)
	return o
end

---------------------------------------------------------------------------
-- Creates a table with the raw data of the object.
-- @class function
-- @name rawdata
-- @return Table with field=value pairs.
---------------------------------------------------------------------------
local function rawdata (self)
	local r = {}
	for field, f in pairs (self.db_fields) do
		r[field] = rawget (self, field)
	end
	return r
end

---------------------------------------------------------------------------
-- Inserts a new record in the database.
-- @class function
-- @name insert
-- @return Boolean indicating the success of the operation.
---------------------------------------------------------------------------
local function insert (self)
	return self.__dado:insert (self.table_name, self:rawdata ()) == 1
end

---------------------------------------------------------------------------
-- Updates the data of the object in the corresponding database record.
-- @class function
-- @name update
-- @return Boolean indicating the success of the operation.
---------------------------------------------------------------------------
local function update (self)
	return self.__dado:update (self.table_name, self:rawdata (), self:db_identification ()) == 1
end

---------------------------------------------------------------------------
-- Saves the object data.
-- This function decides when to perform an update or an insert according
-- to the value of the loaded attribute which indicates if the data was
-- already loaded from the database.
-- @class function
-- @name save
---------------------------------------------------------------------------
local function save (self)
	if self.loaded then
		return self:update ()
	else
		return self:insert ()
	end
end

---------------------------------------------------------------------------
-- Creates a new class.
-- @class function
-- @name class
-- @param c Table with the mandatory fields.
-- @return Table representing the class.
---------------------------------------------------------------------------
local function class (self, c)
	setmetatable (c, { __index = self })
	return c
end

--------------------------------------------------------------------------------
return {
	_COPYRIGHT = "Copyright (C) 2008-2017 PUC-Rio",
	_DESCRIPTION = "Database Object is a library to create classes and objects associated with database tables and rows",
	_VERSION = "Dado Object 1.8.3",

	db_identification = db_identification,
	new = new,
	rawdata = rawdata,
	insert = insert,
	update = update,
	save = save,
	class = class,
}
