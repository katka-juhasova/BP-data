#!/usr/bin/env lua


local DBI = require "DBI"
local sqlconn = require "sqltable.connection"



---
-- A connection pooling object.
--
-- This allows for lots of tables to be opened with only
-- as many connections as are needed to be created. Also,
-- it provides for some level of fault tolerance: stale connections
-- are automatically purged.
--
local _pool = {}



--
-- We need coroutine-safe pcall. Lua 5.2 can do it, but Lua 5.1
-- needs a helper library to do it
--
local _pcall
if _VERSION == 'Lua 5.1' then
	assert(require "coxpcall", "coxpcall required for Lua 5.1")
	_pcall = copcall
	table.unpack = unpack
else
	_pcall = pcall
end


---
-- Opens a new connection.
--
-- @param params Table of named parameters (see LuaDBI for details)
-- @return A new pool object
--
local function open( params )

	local connect_args = {
			params.type,
			params.name,
			params.user,
			params.pass or nil,
			params.host or 'localhost',
			params.port or 5432
		}
		
	local raw_conn = assert(DBI.Connect(table.unpack(connect_args)))
	local connection = sqlconn.new( raw_conn )
	
	return connection

end


---
-- Close the connection handed to us, for any reason.
--
-- Since the connection could be bad, pcall() everything.
--
local function close_connection( connection )
		
	pcall(connection.close, connection)
		
end


---
-- Return the type of database this pool connects to.
--
-- @param pool Pool to checked
-- @return Database type of pool
--
function _pool.type( pool )
	return getmetatable(pool).type
end


---
-- Checkout a connection from the pool for use.
--
-- @param pool Pool to retrieve connection from
-- @return A usable LuaDBI connection
--
function _pool.get( pool )

	local meta = getmetatable(pool)
	local ret = nil
	
	if #(meta.connections) > 0 then
		ret = table.remove(meta.connections, 1)
	else	
		ret = open( meta.params )
			
		if meta.setup_hook then
			meta.setup_hook( ret )
		end
	end

	meta.outstanding[ ret ] = true
	return ret
end


---
-- Return a connection to the pool.
--
-- @param pool Pool receiving connection
-- @param connection Connection to be returned
--
function _pool.put( pool, connection )

	local meta = getmetatable(pool)
	
	-- make sure the connection is alive before placing it in the
	-- pool. Maybe should remove this
	if not connection.ping() then 
		meta.outstanding[ connection ] = nil
		return 
	end
	
	table.insert(meta.connections, connection)
	meta.outstanding[ connection ] = nil

end


---
-- Returns a count of the total number of connections this
-- pool has open.
--
-- @param pool Pool to check
-- @return Total number of connections in pool
--
function _pool.connections( pool )

	local meta = getmetatable(pool)
	return #(meta.connections) + pool:outstanding()

end


---
-- Returns a count of connections that exist, but are in use
-- and not waiting in the pool.
--
-- @param pool Pool to check
-- @return Number of outstanding connections in pool
--
function _pool.outstanding( pool )

	local meta = getmetatable(pool)
	local sum = 0
	
	for k, v in pairs(meta.outstanding) do sum = sum + 1 end
	return sum
	
end


---
-- Shuts down the pool.
--
-- THIS EXPLODES BADLY if there are outstanding connections not
-- yet returned. Stop all queries before calling it!
--
-- @param pool Pool to close
--
function _pool.close( pool )

	local meta = getmetatable(pool)
	
	if pool:outstanding() > 0 then
		error("Cannot close: "..pool:outstanding().." connections not returned.")
	end

	for i, connection in ipairs(meta.connections) do
		close_connection(connection)
	end
	
	-- break the pool object. It's closed, right?
	setmetatable(
		pool, 
		{ 
			__index = function() error("pool is closed") end,
			__newindex = function() error("pool is closed") end
		}
	)

end


---
-- Resets a pool by closing all connections, then reconnecting
-- with just one. This is handy if your program forks and/or you
-- want to recycle all file handles.
--
-- @param pool Pool to reset
--
function _pool.reset( pool )

	local meta = getmetatable(pool)
	
	if pool:outstanding() > 0 then
		error("Cannot reset: "..pool:outstanding().." connections not returned.")
	end
	
	for i, connection in ipairs(meta.connections) do
		close_connection(connection)
	end

	-- reopen.
	meta.connections = {}
	meta.outstanding = {}
	pool:put( pool:get() )

end


---
-- Sets a 'setup hook' that will be called every time a new
-- connection is opened.
--
-- The pool will be reset once a hook is set, thus closing all
-- open connections and reconnecting.
--
-- @param pool this pool object
-- @param fcn Setup hook to call
-- @returns nothing
--
function _pool.setup_hook( pool, fcn )

	meta = getmetatable(pool)
	meta.setup_hook = fcn
	pool:reset()

end



--
-- Methods for the pool object.
--
local _methods = {

	-- set readonly
	__newindex = function() end

}


---
-- "Connect" to a database. This opens the first connection to
-- a database to ensure the settings are correct, then returns
-- a pool object containing one connection.
--
function _pool.connect( params )

	assert(type(params) == 'table', "No connection args!")
	assert(params.type, "Database type must be provided")
	assert(params.name, "Database name must be provided")
	
	if not params.type == 'SQLite3' then
		assert(params.user, "Database user must be provided")
	end

	local ret = {}
	local ret_meta = {
	
		outstanding = {},
		connections = {},
		params = params,
		type = params.type
	
	}
	
	for name, method in pairs(_pool) do
		ret[name] = method
	end
	
	for name, method in pairs(_methods) do
		ret_meta[name] = method
	end
	
	ret.connect = nil
	setmetatable(ret, ret_meta)
	ret:put( ret:get() )
	
	return ret
	
end


return _pool
