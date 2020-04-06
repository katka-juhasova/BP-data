#!/usr/local/bin/lua

local x = {}

---
-- Deimos utility functions.
--
-- These routines are generic enough to fork out. Equivalents
-- might exist in another off-the-shelf library, but they are
-- simple enough I didn't bother to look.
--


---
-- Shallow (no recursion) clone of a table.
--
-- @param source Table to clone
-- @return A copy of the provided table
--
function x.clone(source)

	local ret = {}

	for k, v in pairs(source) do
		ret[k] = v
	end

	return ret

end



---
-- Merge two tables. Copies data from one table into another, while
-- leaving the existing contents of the destination table in place.
--
-- @param dest Destination table, where data is copied to
-- @param source Source table, where data is copied from.
--
-- @return The same table as dest, now containing the keys from source.
--
function x.merge(dest, source)

	local ret = {}

	for k, v in pairs(source) do
		dest[k] = v
	end

	return dest

end


return x
