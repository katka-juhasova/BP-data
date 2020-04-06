#!/usr/bin/env lua5.3

---
-- A wrapper around LuaDBI's connection object that caches prepared
-- statements for reuse.
--
local _sqltable_connection = {}


---
-- Proxy for prepare() that leaves the cached object.
--
-- @param this Connnection to prepare a statement through
-- @param code SQL code to prepare
-- @return Prepared statement handle
--
local function prepare( this, code )

	assert(type(this) == 'table', "incorrect prepare usage")

	if this.statements[code] then
		this.hits = this.hits + 1
		return this.statements[code]
	end
	
	local statement, err = this.conn:prepare( code )

	if not statement then
		return nil, err
	end
	
	this.misses = this.misses + 1
	this.statements[code] = statement
	return statement

end


---
-- Purge a cached statement object, because something
-- has gone wrong.
--
-- @param this Connection we are clearing cache on
-- @param statement Statement being removed from the cache, as a string SQL code
--
local function purge( this, statement )

	local sth = this.statements[statement]
	assert(sth, "No statement to remove")

	this.statements[statement] = nil
	sth:close()

end


---
-- Cleanup after ourselves.
--
-- MySQL requires all statements to be closed before we
-- can close the connection. (https://bugs.mysql.com/bug.php?id=73)
--
-- @param this Connection being closed
--
local function close( this )

	for c, statement in pairs(this.statements) do
		statement:close()
	end
	
	this.conn:close()

end


---
-- Count of cached statements.
--
-- @param this Connection to report cached statements
--
-- @return Number of statements cached
--
local function statement_count( this )

	local count = 0
	for s, c in pairs(this.statements) do
		count = count + 1
	end
	
	return count

end


---
-- Emulates all other methods via a metamethods
--
local function proxy( this, index )

	return function( ... ) 
		return this.conn[index]( this.conn, ... ) 
	end

end


---
-- Wrap a connection.
--
-- @param conn Connection from LuaDBI to wrap
-- @return SqlTable wrapped connection object
--
function _sqltable_connection.new( conn )

	---
	-- A SqlTable connection object
	--
	local _sqltable_conn = {
		hits = 0,			-- @field Number of cache hits
		misses = 0,			-- @field Number of cache misses
		statements = {},	-- @field The actual statement cache
		conn = conn,		-- @field Underlying LuaDBI connection
		
		prepare = prepare,
		purge = purge,
		close = close,
		statement_count = statement_count
	}


	setmetatable(_sqltable_conn, {
		__index = function( this, idx )	
			return proxy(this, idx)
		end
	})


	return _sqltable_conn

end




return _sqltable_connection
