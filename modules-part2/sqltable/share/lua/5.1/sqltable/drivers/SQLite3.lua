#!/usr/bin/env lua

---
-- SQLite3 code generator and insert_id handling logic.
--
local sqlite = {}


---
-- Generates a well formed placeholder.
--
function sqlite.placeholder( num )
	-- SQLite will take either MySQL style '?' or PostgreSQL style
	-- numbered arguments
	return "$" .. tostring(num)
end


---
-- Generates a sqlite select statement.
--
function sqlite.select_all( tablename )
	return "select * from " .. tablename
end


---
-- Generates a sqlite select with where clause.
--
function sqlite.select_where( tablename, keyname )
	return string.format(
			"select * from %s where %s = %s",
				tablename,
				keyname,
				sqlite.placeholder(1)
			)
end


---
-- Generates a sqlite insert statement.
--
function sqlite.insert( tablename, keyname, columns )

	local value_placeholders = {}
	
	for column in pairs( columns ) do
		table.insert(
			value_placeholders, 
			sqlite.placeholder( #value_placeholders + 1 )
		)
	end
	
	return string.format(
			"insert into %s ( %s ) values ( %s )",
				tablename,
				table.concat(columns, ', '),
				table.concat(value_placeholders, ', ')
		)
end


---
-- Generates a sqlite update statement.
--
function sqlite.update( tablename, keyname, columns )

	local column_lines = {}

	for column in pairs( columns ) do
		local placeholder = sqlite.placeholder( #column_lines + 1 )
	
		table.insert(
			column_lines,
			tostring(column) .. ' = ' .. placeholder
		)
	end

	return string.format(
			"update %s set %s where %s = %s",
				tablename,
				table.concat(column_lines, ', '),
				keyname,
				sqlite.placeholder( #column_lines + 1 )
		)
end


---
-- Generates a sqlite delete statement.
--
function sqlite.delete( tablename, keyname )
	return string.format(
			"delete from %s where %s = %s",
				tablename,
				keyname,
				sqlite.placeholder(1)
		)
end


---
-- Generates a sqlite size-of-table query.
--
function sqlite.count( tablename )
	return string.format("select count(*) num from %s", tablename)
end


---
-- Generates a Sqlite version number request.
--
function sqlite.version( )
	return "select sqlite_version();"
end


---
-- Extracts the new row ID from an insert statement. Every database
-- has different ways of handling this.
--
function sqlite.get_last_key( keyname, connection, statement )
	return connection:last_id()
end


---
-- Post-processor for data that needs to be transmuted
-- The one here for sqlite does something: turns int's into booleans
-- when requested
--
function sqlite.post_processor( vendor_data, data )

	if not vendor_data then return data end
	if not vendor_data.booleans then return data end

	for i, v in ipairs(vendor_data.booleans) do
		if data[v] then
			data[v] = tonumber(data[v]) > 0
		end
	end
	
	return data
end


return sqlite
