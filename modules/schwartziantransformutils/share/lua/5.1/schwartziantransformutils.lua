------------
-- ## Schwartzian Transformation utilities for Lua.
--
-- @module schwartzianTransformUtils

local stu = {}

--- Sort a table and return the sorted table.
-- @param f table to be sorted
-- @return sorted table
function stu:sort(f)
   table.sort(self, f)
   return self
end

--- Get the keys from a table.
-- @return an array of keys
function stu:keys()
   local keys = {}
   for key in pairs(self) do
      table.insert(keys, key)
   end
   return keys
end

--- Get the values from a table.
-- @return an array of values
function stu:values()
   local values = {}
   for _,val in pairs(self) do
      table.insert(values, val)
   end
   return values
end

--- Perform a function on each value in an array.
-- @param f function to be called as f(self, val, r)
function stu:map(f)
   local r = {}
   for _,val in pairs(self) do
      f(self, val, r)
   end
   return r
end

return stu
