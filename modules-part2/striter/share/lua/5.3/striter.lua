---
-- The striter module.
-- It allows creating striter objects, which can be used to iterate through a
-- string or file.
-- @classmod striter
---

local m = {}
m.__index = m

--- Create a new striter object.
-- @function striter.new
-- @tparam string|file arg the source of data for the striter
-- @treturn striter the striter object
function m.new(arg)
	if io.type(arg) == "file" then
		local file = arg
		arg = file:read("a*")
		file:close()
	end

	if type(arg) ~= "string" then
		return nil, "Input must be an open file or a string."
	end

	local self = setmetatable({}, m)
	self.__index = 0
	self.__string = arg
	return self
end

--- Advance characters in the iterator
-- @function striter:next
-- @tparam[opt] int n the characters to advance (default is 1)
-- @treturn string|nil the next characters
function m:next(n)
	if n == nil then
		n = 1
	end

	local value = self.__string:sub(self.__index + 1, self.__index + n)
	self.__index = self.__index + n
	return #value ~= 0 and value or nil
end

--- Peek the next characters
-- @function striter:peek
-- @tparam[opt] int n the characters to peek (default is 1)
-- @treturn string|nil the peeked characters
function m:peek(n)
	if n == nil then
		n = 1
	end

	local value = self.__string:sub(self.__index+1, self.__index+n)
	return #value ~= 0 and value or nil
end

return m
