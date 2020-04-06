#!/usr/bin/env lua

---
-- The 'table' is the central object in SqlTable. Imagine that!
--
local _table = {}


---
-- A 'magic' value: when inserting new rows with auto incrementing
-- primary keys, we don't have a key yet. 
--
-- Using this value as a key is to indicate that a new row is being
-- inserted, with the primary key to be determined by the database.
--
_table.next = setmetatable(
	{}, 
	{ 
		__tostring = function() return 'SqlTableNextRow' end,
		__metatable = false
	}
)


---
-- The Table class's metamethods.
--
local methods = {

	__index = function ( t, key )
		return _table.select( t, key )
	end,
	
	__newindex = function ( t, key, data )
	
		local table_state = getmetatable(t)
			
		if data then
		
			assert(type(data) == 'table', "Expected a table")
	
			-- we've been explicitly tasked with an insert.
			if key == _table.next then
				_table.insert( t, data )
				return
			end
			
			data[ table_state.key ] = key
	

			--
			-- If we have an upsert method, use it
			--
			if _table.upsert then
				_table.upsert( t, data )
			else
				--
				-- fallback for no upsert support
				--
				-- not a very good way to check if we have to insert or
				-- update, but then again, some databases don't have an
				-- upsert command.
				--
				if _table.select( t, key ) then
					_table.update( t, data )
				else
					_table.insert( t, data )
				end
			end
	
		else
		
			-- nil'ing this entry: it's a delete op instead.
			local row = {}
			row[ table_state.key ] = key
			_table.delete( t, row )
			
		end
	
	end,

	
	--
	-- I'm leaving this here for now. I'm not sure if I like the idea.
	-- Basically, this:
	-- local next_row_id = t + { flag1 = true }
	--
	-- ...and have next_row_id be the autoincremented ID of the just 
	-- inserted row.
	--
	-- It's kinda slick but also not exactly obvious what's happening.
	--
	--__add = function ( t, values )
		--return _table.insert( t, values )
	--end,
	
	
	--
	-- Lua 5.2 support
	--
	__pairs = function ( t )
		return _table.all_rows(t)
	end,
	
	__ipairs = function ( t )
		return _table.all_rows(t)
	end,

	__len = function ( t )
		return _table.count(t)
	end

}


---
-- Opens a new table object.
--
function _table.new( env, params )

	assert(type(params) == 'table', "No table args!")
	assert(params.name, "Table name must be provided")
	assert(params.key, "Column name of key must be provided")
		
	local ret = {
	
		env = env,
		key = params.key,
		name = params.name,
		vendor = params.vendor,
		alive = true
	
	}
	
	--
	-- Hide our table state information in the metatable, to prevent
	-- key collisions with the database.
	--
	local metatable = ret
	for k, v in pairs(methods) do metatable[k] = v end
	
	--
	-- Readonly? Then replace _newindex with something that errors.
	--
	if params.readonly then metatable.__newindex = function()
			error("This table is read-only")
		end
	end
	
	return setmetatable({}, metatable)
	
end


---
-- Generates an advanced iterator for returning all rows, safely
-- pcall-wrapped by the environments exec() routine.
--
local function rows( data, code, values )

	local func = function( connection, statement )
		local row_get = statement:rows(true)
		local row = nil
				
		repeat
			row = row_get()
		
			if row then
				local key = row[ data.key ]
				local value = data.env.db_hooks.post_processor(data.vendor, row)
			
				assert(key, "Key is invalid!")
				coroutine.yield(key, value)
			end
			
		until not row	
	end

	return coroutine.wrap( function() 
		if data.connection then
			data.env:exec_internal( data.connection, code, values, func )
		else
			data.env:exec( code, values, func )
		end
	end)
	
end


---
-- Kinda like 'pairs' or 'ipairs' that iterates over all rows
--
function _table.all_rows( t )

	local data = getmetatable(t)
	local code = data.env.db_hooks.select_all( data.name )
	
	return rows( data, code, {} )

end


---
-- Gets just a small part of the table, and returns a pairs() style
-- iterator for that select by adding a user provided where clause.
--
function _table.where( t, clause, ... )

	local data = getmetatable(t)
	local code = data.env.db_hooks.select_all( data.name )
	code = code  .. " where " .. clause
	
	return rows( data, code, {...} )
	
end


---
-- Grab a specific value
--
function _table.select( t, key )

	local data = getmetatable(t)
	local env = data.env
	local row = nil
		
	local code = env.db_hooks.select_where( data.name, data.key )
	local values = { key }
	
	
	local callback = function( connection, statement )
		row = statement:fetch(true)
	end
	
	if data.connection then
		env:exec_internal( data.connection, code, values, callback )
	else
		env:exec( code, values, callback )
	end

	if row then
		return env.db_hooks.post_processor( data.vendor, row )
	end

	return nil

end


---
-- Gets the number of rows in a table.
--
function _table.count( t, where, ... )

	local data = getmetatable(t)
	local env = data.env
	local values = nil
	local row = nil
	
	local code = env.db_hooks.count( data.name )	
	
	if where then
		code = code .. " where " ..  where
		values = {...}
	end
	
	
	local callback = function( connection, statement )
		row = statement:fetch(true)
	end
	
	if data.connection then
		env:exec_internal( data.connection, code, values, callback )
	else
		env:exec( code, values, callback )
	end
	
	return row.num
	
end


---
-- Inserts
--
function _table.insert( t, row )

	local data = getmetatable(t)
	local env = data.env

	local columns = {}
	local values = {}
	
	for k, v in pairs(row) do
		table.insert(columns, k)
		table.insert(values, v)
	end
	
	local code = env.db_hooks.insert(
				data.name,  
				data.key,
				columns
		)
				
	local last_insert = nil
	local callback = function( connection, statement )	
		last_insert = env.db_hooks.get_last_key( 
			data.key, 
			connection, 
			statement 
		)
		
		-- no-op: clear state of the statement handle
		statement:rows()
	end
	
	if data.connection then
		env:exec_internal( data.connection, code, values, callback )
	else
		env:exec( code, values, callback )
	end

	data.last_insert_id = last_insert
	return last_insert

end


---
-- Updates
--
function _table.update( t, row )

	local data = getmetatable(t)
	local env = data.env
	local values = {}
	local code = env.db_hooks.update(
				data.name,  
				data.key,
				row
		)
	

	for k, v in pairs(row) do
		table.insert(values, v)
	end
	
	local function callback( connection, statement )
		-- no-op: clear state of the statement handle
		statement:rows()
	end
	
	-- add the primary key's value to the end, since it will always
	-- be the last part of the update statement. We can't update
	-- without it.
	assert(row[data.key], "Update didn't specify the primary key.")
	table.insert(values, row[data.key])
	
	if data.connection then
		env:exec_internal( data.connection, code, values, callback )
	else
		env:exec( code, values, callback )
	end
	
	return true

end


--- 
-- Delete a row
--
function _table.delete( t, row )

	local data = getmetatable(t)
	local env = data.env
	local values = {}
	local code = env.db_hooks.delete(
				data.name,  
				data.key
		)
	
	local function callback( connection, statement )
		-- no-op: clear state of the statement handle
		statement:rows()
	end
		
	assert(row[data.key], "Delete didn't specify the primary key")
	
	if data.connection then
		env:exec_internal( data.connection, code, { row[data.key] }, callback )
	else
		env:exec( code, { row[data.key] }, callback )
	end
	
	return true

end

return _table
