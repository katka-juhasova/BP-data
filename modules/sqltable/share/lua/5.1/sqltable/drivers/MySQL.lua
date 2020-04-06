#!/usr/bin/env lua

---
-- MySQL code generator and insert_id handling logic.
--
local mysql = {}


---
-- Generates a well formed placeholder.
--
function mysql.placeholder( num )
	-- MySQL is braindead. Ignore the argument.
	return "?"
end


---
-- Generates a MySQL select statement.
--
function mysql.select_all( tablename )
	return "select * from " .. tablename
end


---
-- Generates a MySQL select with where clause.
--
function mysql.select_where( tablename, keyname )
	return string.format(
			"select * from %s where %s = %s",
				tablename,
				keyname,
				mysql.placeholder()
			)
end


---
-- Generates a MySQL insert statement.
--
function mysql.insert( tablename, keyname, columns )

	local value_placeholders = {}

	return string.format(
			"insert into %s ( %s ) values ( %s )",
				tablename,
				table.concat(columns, ', '),
				string.rep(mysql.placeholder() .. ', ', #columns - 1) .. '?'
		)
end


---
-- Generates a MySQL update statement.
--
function mysql.update( tablename, keyname, columns )

	local column_lines = {}

	for column in pairs( columns ) do
		table.insert(
			column_lines, 
			tostring(column) .. ' = ' .. mysql.placeholder()
		)
	end

	return string.format(
			"update %s set %s where %s = %s",
				tablename,
				table.concat(column_lines, ', '),
				keyname,
				mysql.placeholder()
		)
end


---
-- Generates a MySQL delete statement.
--
function mysql.delete( tablename, keyname )
	return string.format(
			"delete from %s where %s = %s",
				tablename,
				keyname,
				mysql.placeholder()
		)
end


---
-- Generates a MySQL size-of-table query.
--
function mysql.count( tablename )
	return string.format("select count(*) num from %s", tablename)
end


---
-- Generates a MySQL version number request.
--
function mysql.version( )
	return "select version();"
end


---
-- Extracts the new row ID from an insert statement. Every database
-- has different ways of handling this.
--
function mysql.get_last_key( keyname, connection, statement )
	return connection:last_id()
end


---
-- Post-processor for data that needs to be transmuted
-- The one here for MySQL does something: turns int's into booleans
-- when requested
--
function mysql.post_processor( vendor_data, data )

	if not vendor_data.booleans then return data end

	for i, v in ipairs(vendor_data.booleans) do
		if data[v] then
			data[v] = tonumber(data[v]) > 0
		end
	end
	
	return data
end


return mysql
