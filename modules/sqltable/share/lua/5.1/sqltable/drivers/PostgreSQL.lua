#!/usr/bin/env lua

---
-- PostgreSQL code generator and insert_id handling logic.
--
local postgres = {}


---
-- Generates a PostgreSQL-syntax placeholder.
--
function postgres.placeholder( num )
	return '$' .. tostring(num)
end


---
-- Generates a PostgreSQL select statement.
--
function postgres.select_all( tablename )
	return "select * from " .. tablename
end


---
-- Generates a PostgreSQL select with where clause.
--
function postgres.select_where( tablename, keyname )
	return string.format(
			"select * from %s where %s = %s",
				tablename,
				keyname,
				postgres.placeholder(1)
			)
end


---
-- Generates a PostgreSQL insert statement.
--
function postgres.insert( tablename, keyname, columns )

	local value_placeholders = {}

	for column in pairs( columns ) do
		table.insert(
			value_placeholders, 
			postgres.placeholder( #value_placeholders + 1 )
		)
	end

	return string.format(
			"insert into %s ( %s ) values ( %s ) returning %s",
				tablename,
				table.concat(columns, ', '),
				table.concat(value_placeholders, ', '),
				keyname
		)
end


---
-- Generates a PostgreSQL update statement.
--
function postgres.update( tablename, keyname, columns )

	local column_lines = {}

	for column in pairs( columns ) do
		local placeholder = postgres.placeholder( #column_lines + 1 )
	
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
				postgres.placeholder( #column_lines + 1 )
		)
end


---
-- Generates a PostgreSQL delete statement.
--
function postgres.delete( tablename, keyname )
	return string.format(
			"delete from %s where %s = %s",
				tablename,
				keyname,
				postgres.placeholder(1)
		)
end


---
-- Generates a PostgreSQL size-of-table query.
--
function postgres.count( tablename )
	return string.format("select count(*) as num from %s", tablename)
end


---
-- Generates a PostgreSQL version number request.
--
function postgres.version( )
	return "select version();"
end


---
-- Extracts the new row ID from an insert statement. Every database
-- has different ways of handling this.
--
function postgres.get_last_key( keyname, connection, statement )
	if statement:rowcount() == 1 then
		local row = statement:fetch(true)
		return row[ keyname ]
	end
	
	return nil
end


---
-- Postgres's post-processor is a noop, no data needs to be
-- transformed.
--
function postgres.post_processor( vendor_data, data )
	return data
end


---
-- 
--


return postgres
