#!/usr/bin/env lua

---
-- Methods for the Environment object: the top level user API
-- to SqlTable.
--

--local dml = require "sqltable.dml"
local s_table = require "sqltable.table"


local _pcall
if _VERSION == 'Lua 5.1' then
	assert(require "coxpcall", "coxpcall required for Lua 5.1")
	_pcall = copcall
else
	_pcall = pcall
end


---
-- SqlEnvironment
--
local _sqltable_env = {}


---
-- Returns how many connections SqlTable has open
-- to the database.
--
-- @param this Environment object
-- @return Number of existant connections
--
function _sqltable_env.connections( this )
	return this.pool:connections()
end


---
-- Shuts down this environment.
--
-- @param this Environment object being closed
-- @return Nothing.
--
function _sqltable_env.close( this )
	return this.pool:close()
end


---
-- Reset the environment: leave the environment open, but close
-- all existing connections and open new ones for future calls.
--
-- This method comes in handy should your Lua script fork into a second
-- process.
--
-- @param this Environment object being reset
-- @return Nothing.
--
function _sqltable_env.reset( this )
	return this.pool:reset()
end


---
-- Provide a setup hook for new database connections that are opened,
-- to configure any variables/PRAGMA options/etc that may be needed.
--
-- The pool will be reset once a hook is set, thus closing all
-- open connections and reconnecting.
--
-- @param this Environment object being reset
-- @param fcn Function to implement connection setup
-- @return Nothing.
--
function _sqltable_env.setup_hook( this, fcn )
	return this.pool:setup_hook( fcn )
end


---
-- A 'magic' value: when inserting new rows with auto incrementing
-- primary keys, we don't have a key yet. 
--
-- Using this value as a key indicates to SqlTable that a new row is 
-- being inserted, with the primary key to be determined by the 
-- database.
--
-- @see _sqltable_env.last_insert_id
--
_sqltable_env.next = s_table.next


---
-- Manually execute a database query.
--
-- The arguments returned to the callback function are raw LuaDBI
-- Userdata. See documentation for LuaDBI at 
-- http://code.google.com/p/luadbi/w/list for API details.
--
-- @param this Environment object
-- @param query Text of SQL query to execute
-- @param[opt] values Table of values to bind to the query (if needed)
-- @param[opt] callback Function that is called to handle returned data
--
-- @usage
--t:exec( "select name from t_employees where where title = $1", { 'Programmer' }, 
--	function( connection, statement )
--		local row = true		
--
--		while row do
--			row = statement:fetch(true)
--			do_stuff(row)
--		end
--	end
--)
--
function _sqltable_env.exec( this, query, values, callback )
	
	local connection = this.pool:get()
	local res, err = _pcall(function()
		this:exec_internal( connection, query, values, callback )
	end)
	
	if not res then
		connection:rollback()
		this.pool:put(connection)
		error(err)
	end

	connection:commit()
	this.pool:put(connection)

end


--
-- Execute with the specified database handle instead. No transaction
-- details.
--
-- @param this Environment object
-- @param[opt] connection Connection handle to use, if in a transaction
-- @param query Text of SQL query to execute
-- @param[opt] values Table of values to bind to the query (if needed)
-- @param[opt] callback Function that is called to handle returned data
--
function _sqltable_env.exec_internal( this, connection, query, values, callback )

	local statement = nil
	local in_transaction = false

	values = values or {}
	assert(connection, "Need a connection to execute")

	local success, err = _pcall(function()
	
		if this.debug_hook then
			this.debug_hook( query, values or {} )
		end
		
		statement = assert(connection:prepare(query))

		if values then
			assert(statement:execute( table.unpack(values) ))
		else
			assert(statement:execute())
		end
		
		-- callback is optional.
		if callback then
			callback( connection, statement )
		end
	
	end)

	if not success then

		-- delete a statement if it did successfully prepare,
		-- to clear out any error states
		if statement then
			connection:purge(query)
		end
		
		connection.rollback()
		
		-- bubble the error back to the top.
		error(err)
		
	end

end


--
-- The below look weird due to a ldoc hack to make these appear
-- as functions. Only causes a performance hit during script load, and
-- it's pretty minor.
--

---
-- Manually perform a select statement.
--
function _sqltable_env.select() end 
_sqltable_env.select= s_table.select


---
-- Manually perform  an insert statement.
--
function _sqltable_env.insert() end 
_sqltable_env.insert = s_table.insert


---
-- Manually perform  an update statement.
--
function _sqltable_env.update() end 
_sqltable_env.update = s_table.update


---
-- Manually perform  a delete statement.
--
function _sqltable_env.delete() end 
_sqltable_env.delete = s_table.delete


---
-- Execute a select that counts rows.
--
-- @param tbl Table being row counted
-- @param[opt] clause Optional where clause
-- @param[opt] ... Optional bound parameters for where clause
-- @return Integer number of rows
--
-- @usage
-- total_employees = env.count( t_employees )
-- programmers = env.count( t_employees, "where title = $1", 'Programmer' )
--
function _sqltable_env.count( tbl, clause, ... ) end
_sqltable_env.count = s_table.count


---
-- Returns a version string identifying the version of the
-- underlying database.
--
-- Please note that the exact format of the returned data may vary
-- from database to database.
--
-- @return String containing version information
--
function _sqltable_env.version( this )

	local vers = ""
	
	this:exec( this.db_hooks.version(), {}, function( conn, statement )
        row = statement:fetch(false)
        vers = row[1]
	end )

	return vers

end


---
-- Execute a select all rows, returning an iterator. 
--
-- @param tbl Table to select from
-- @return Iterator function similar in usage to pairs().
--
-- @usage
-- for id, employee in env.all_rows( t_employees ) do
--	print(id, employee.name)
-- end
--
function _sqltable_env.all_rows( tbl ) end
_sqltable_env.all_rows = s_table.all_rows


---
-- Execute a select, as limited by a where clause, returning an 
-- iterator. Identical to all_rows() except permits a where clause.
--
-- @param tbl Table to select from
-- @param[opt] clause Optional where clause
-- @param[opt] ... Optional bound parameters for where clause
-- @return Iterator function similar in usage to pairs().
--
-- @usage
-- for id, employee in env.where( t_employees, "title = $1", 'Programmer' ) do
--	print(id, employee.name)
-- end
--
function _sqltable_env.where( tbl, clause, ... ) end
_sqltable_env.where = s_table.where


---
-- Retrieve the primary key of the last row that was inserted.
--
-- @param tbl Table object that last query was performed on
-- @return Primary key of last insert.
--
-- @see _sqltable_env.next
--
-- @usage
-- t_employees[ sqltable.next ] = { name = 'Alice', title = 'Programmer' }
-- alice_id = env.last_insert_id( t_employees )
--
function _sqltable_env.last_insert_id( tbl )

	return getmetatable(tbl).last_insert_id

end


---
-- Writes a placeholder value for use in where statements. Helps make 
-- manually crafted queries more portable across databases.
--
-- @param this Environment object
-- @param[opt] nth Specify that this is the n-th placeholder in this
--				query (needed by some database engines)
--
-- @usage
-- sql = "where column = " .. env:placeholder(1)
-- -- "where column = $1" for PostgreSQL
-- -- "where column = ?" for MySQL
--
function _sqltable_env.placeholder( this, nth )
	return this.db_hooks.placeholder( nth )
end


---
-- Apply a debugging hook to this environment. Any SQL call made will
-- be passed to the function, along with a table of any bound
-- parameters placed as part of the call.
--
-- The hook is called before the code is compiled, so the given callback
-- function will be called just before an error is raised.
--
-- The hook can be disabled by calling this method again with no
-- arguments.
--
-- @param this Environment object
-- @param fcn Debugging function
-- 
-- @usage
-- function sql_debug( q, args ) 
--	print(q) 
--	for k, v in pairs(args) do 
--		print(k, '"'..tostring(v)..'"') 
--	end 
-- end
--
-- db.env:debugging( sql_debug )
--
function _sqltable_env.debugging( this, fcn )

	-- nil means disable.
	if not fcn then
		this.debug_hook = nil
		return
	end
	
	assert(
		type(fcn) == 'function', 
		'You lied to me when you told me this was a function.'
	)
	
	this.debug_hook = fcn
	
end


---
-- Slurps the result set of an entire query into memory so that normal 
-- pairs() can work. The key is chosen from the table's specified key 
-- column.
--
-- THIS IS NOT VERY PERFORMANT WHEN USED WITH LARGE TABLES. 
-- Use caution.
--
-- @param tbl Table object to clone
-- @param where Optional where clause
-- @param ... Parameters to where clause
-- @return Table of data as returned by select
--
-- @usage
-- programmers = env.clone( t_employees, "where title = $1", 'Programmer' )
-- all_employees = env.clone( t_employees )
--
-- for name, title in pairs(all_employees) do
--	print(name, title)
-- end
--
function _sqltable_env.clone( tbl, where, ... )

	local ret = {}
	
	if where then
		for k, v in _sqltable_env.where( tbl, where, ... ) do
			ret[k] = v
		end
	else
		for k, v in _sqltable_env.all_rows( tbl ) do
			ret[k] = v
		end
	end

	return ret
	
end


---
-- Slurps the result set of an entire query into memory so that normal 
-- ipairs() can work. The key starts at one and increments per row, 
-- forming a standard Lua array.
--
-- THIS IS NOT VERY PERFORMANT WHEN USED WITH LARGE TABLES. 
-- Use caution.
--
-- @param tbl Table object to clone
-- @param where Optional where clause
-- @param ... Parameters to where clause
-- @return Table of data as returned by select
--
-- @usage
-- programmers = env.iclone( t_employees, "where title = $1", 'Programmer' )
-- all_employees = env.iclone( t_employees )
--
-- for employee_id, name in ipairs(all_employees) do
--	print(employee_id, name)
-- end
--
function _sqltable_env.iclone( tbl, where, ... )

	local ret = {}
	
	if where then
		for k, v in _sqltable_env.where( tbl, where, ... ) do
			ret[ #ret + 1 ] = v
		end
	else
		for k, v in _sqltable_env.all_rows( tbl ) do
			ret[ #ret + 1 ] = v
		end
	end

	return ret
	
end


---
-- Start a consistant transaction on a table.
--
-- The table will be locked to a single SQL connection with
-- autocommit mode disabled and a new transaction started.
-- You will need to call 'commit' or 'rollback' before the table
-- is garbage collected, or a SQL connection will be leaked.
--
-- @param this SqlTable environment
-- @param tbl Table transaction is starting on
--
function _sqltable_env.begin_transaction( this, tbl )

	assert(this)
	assert(tbl, "Table not provided")

	local data = getmetatable(tbl)
	assert(not data.connection, "Table already in transaction")
	
	data.connection = this.pool:get()

end


---
-- Commit a table's transaction.
--
-- All changes to the table will be saved. The SQL connection will be 
-- returned to the pool and set back to autocommit mode.
--
-- @param this SqlTable environment
-- @param tbl Table to commit to transaction on
--
function _sqltable_env.commit( this, tbl )

	assert(this)
	assert(tbl, "Table not provided")
	
	local data = getmetatable(tbl)
	assert(data.connection, "Table not in transaction")
	
	data.connection:commit()
	
	this.pool:put( data.connection )
	data.connection = nil

end


---
-- Rollback a table's transaction
--
-- All changes will be reverted back to when begin_transaction was
-- run. The SQL connection will be returned to the pool and set back
-- to autocommit mode.
--
-- @param this SqlTable environment
-- @param tbl Table to rollback transaction on
--
function _sqltable_env.rollback( this, tbl )

	assert(this)
	assert(tbl, "Table not provided")
	
	local data = getmetatable(tbl)
	assert(data.connection, "Table not in transaction")
	
	data.connection:rollback()
	
	this.pool:put( data.connection )
	data.connection = nil
	
end


---
-- Arguments for opening a table.
--
-- @field name Name of table, in database
-- @field key Primary key of table
-- @field vendor Table of database-specific parameters
-- @field readonly If set to true, updates, inserts, and deletes 
--		will be disabled.
-- @table TableParameters
--


---
-- Open a proxy table to a database table.
--
-- @param this Environment Object
-- @param params @{TableParameters}
-- 
-- @return Proxy table object
--
-- @usage
--t_employees = assert(env:open_table{
--	name = 'employees',
--	key = 'employee_id'
--})
--
function _sqltable_env.open_table( this, params )

	return s_table.new( this, params )

end


return _sqltable_env
