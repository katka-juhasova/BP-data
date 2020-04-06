#!/usr/local/bin/lua


local utility = require "deimos/utility"
local x = {}


---
-- Deimos 'class' type.
--
-- Implements an object with fixed key-value pairs,
-- much like a class in other languages.
--


--
-- Metamethods for the class type.
--


local methods = {}

--
-- 'get'
--
function methods.__index( self, key )

	local schema = rawget(self, 'schema')
	
	assert( 
		schema[key], 
		"Can't get unspecified key: " .. tostring(key)
	)
	
	return rawget( self, 'data' )[key]
	
end

--
-- 'set'
--
function methods.__newindex( self, key, data )	

	local schema = rawget(self, 'schema')
	local sdata = rawget(self, 'data')

	assert( 
		schema[key], 
		"Can't set unspecified key: " .. tostring(key)
	)
	
	if not schema[key].nullable then
		assert(data, "Field cannot be nil: " .. tostring(key))
	end
	
	local new_data = schema[key]:validate(data)
	
	if new_data then
		sdata[key] = new_data
	else
		sdata[key] = data
	end
	
end


--
-- Make pairs and ipairs work
--
-- Requires Lua 5.2!
--
function methods.__pairs( self )
	return pairs(rawget(self, 'data'))
end

function methods.__ipairs( self )
	return ipairs(rawget(self, 'data'))
end

function methods.__len( self )
	local data = rawget(self, 'data')
	return #data
end


---
-- Constructs a new class type object.
--
-- @param self The schema of the class being created.
-- @return A new empty class of the defined type.
--
function x.new( self )
		
	local ret = { 
			id = self.id,
			schema = utility.clone(self.schema),
			data = {}
		}

	for k, v in pairs(self.schema) do
		ret.data[k] = v:default()
	end
		
	function ret.pairs(self)
		return pairs(self.data)
	end
		
	setmetatable(ret, methods)
	return ret
	
end


--
--The default of a class is also it's constructor.
--
x.default = x.new


---
-- Tests that 'data' is an object of the same type described by
-- 'schema'.
--
-- @param self Schema object, the type being checked for
-- @param data Data object being tested.
--
-- @return Nothing, unless the object was a valid class, in which
--			case it is filled(). There are no negative cases:
--			errors are thrown if the data is invalid.
--
function x.validate( self, data )

	local data_id = rawget(data, 'id')
	
	--
	-- If there is an ID, check it
	--
	if data_id then
		assert(
			self.id == data_id,
			"Can't set a class to a different type"
		)
	
	--
	-- ...otherwise, fill it
	--
	else
		data, err = self:fill(data)
		assert(data, err)
		
		return data
	end

end


---
--	Recursively fills this class object with the given data.
--
--	@param self Type of object being filled
--	@param data Data to be filled in/validated
--
--	@return A complete class of the given type in 'self', with it's
--			contents set to the contents of 'data'. In the case of
--			a validation error, nil + error message is returned
--			instead.
--
function x.fill( self, data )

	local ret = self:new()
	local err
	
	status, message = pcall( function()
			for k, v in pairs(data) do
				if self.schema[k].fill then
					local value, err = self.schema[k]:fill(v)
					assert(value, err)
					ret[k] = value
				else
					ret[k] = v
				end	
			end
		end)
	
	if not status then 
		return nil, message 
	end
	
	return ret
end


return x
