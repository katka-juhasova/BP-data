#!/usr/bin/env lua

local DBI = require "DBI"
local pool = require "sqltable.pool"
local env = require "sqltable.env"


--[[
Copyright (c) 2013-2017 Aaron B.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--


---
-- SqlTable makes tables in relational databases appear to be ordinary
-- Lua tables.
--
local sqltable = {}


--- Version of SqlTable in use.
sqltable.VERSION = "1.4 2017.1107"


---
-- Supported database types.
--
sqltable.support = {
	PostgreSQL = true,	-- support for PostgreSQL when true.
	MySQL = true,		-- support for MySQL when true.
	SQLite3 = true		-- support for SQLite3 when true.
}
	
	
---
-- Arguments which are passed by @{sqltable.connect} to the underlying
-- database driver.
--
-- @field type Type of database being connected to
-- @field name Name of database
-- @field user Username to connect as
-- @field host Database hostname (optional)
-- @field pass Database password for username (optional)
-- @table ConnectionArguments
--

	
---
-- Creates a new environment.
--
-- @param params @{ConnectionArguments}
-- @return @{sqltable.env}
--
-- @usage 
-- env = sqltable.connect{ type='PostgreSQL', host='dbserver', name='employees' }
--
function sqltable.connect( params )

	local ret = {}

	assert(type(params == 'table'), "No connection args!")
	assert(params.type, "Database type must be provided")
	assert(params.name, "Database name must be provided")
	
	if not params.type == 'SQLite3' then
		assert(params.user, "Database user must be provided")
	end
	
	for k, v in pairs(env) do
		ret[k] = v
	end
	
	ret.pool = pool.connect( params )
	ret.db_hooks = require("sqltable.drivers." .. params.type)
	ret.debug_hook = nil
	
	return ret

end


return sqltable
