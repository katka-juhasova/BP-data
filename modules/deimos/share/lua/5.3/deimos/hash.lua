#!/usr/local/bin/lua


local utility = require "deimos/utility"
local x = {}


---
-- Deimos 'hash' type.
--
-- Implements an array with arbitrary keys mapping to arbitrary
-- values, much like a hashtable.
--


--
-- Metamethods for the hash type.
--


local methods = {}

--
-- 'get'
--
function methods.__index( self, key )
	return rawget( self, 'data' )[key]
end

--
-- 'set'
--
function methods.__newindex( self, key, data )	

	local schema = rawget(self, 'schema')
	local sdata = rawget(self, 'data')

	-- no check for nil: nullable means nothing here. 
	-- the way to remove an item is to set it to nil.

	schema.key:validate(key)
	local new_data = schema.value:validate(data)
	
	if new_data then
		--
		-- The only case of this is replacing the whole array.
		--
		rawset(self, 'data', new_data)
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
-- Constructs a new hash type object.
--
-- @param self The schema of the hash being created.
-- @return A new empty hash of the defined type.
--
function x.new( self )
		
	local ret = { 
			id = self.id,
			schema = utility.clone(self.schema),
			data = {}
		}
		
	--
	-- Fake pairs() for Lua 5.1 users.
	--
	function ret.pairs( self )
		return pairs( ret.data )
	end
		
	--
	-- I find this handy sometimes. Others disagree.
	--
	function ret.count( self )
		local i = 0
	
		for v in pairs( ret.data ) do
			i = i + 1
		end
		
		return i
	end
		
	setmetatable(ret, methods)
	return ret
	
end


--
-- The default of a hash is also it's constructor.
--
x.default = x.new


---
-- Tests that 'data' is an object of the same type described by
-- 'schema'.
--
-- @param self Schema object, the type being checked for
-- @param data Data object being tested.
--
-- @return Nothing, unless the object was a valid hash, in which
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
			"Can't set an array to a different type"
		)
	
	--
	-- ...otherwise, fill it if it's a table
	--
	elseif type(data) == 'table' then
		data, err = self:fill(data)
		assert(data, err)
		
		return data
	end

end


---
--	Recursively fills this array object with the given data.
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
			
				local key = k
				local value = v
				
				--print(key, value)
				if self.schema.key.fill then
					key, err = self.schema.key:fill(v)
					assert(key, err)
				end
			
				if self.schema.value.fill then
					value, err = self.schema.value:fill(v)
					assert(value, err)
				end
			
				ret[key] = value
			end
		end)
	
	if not status then 
		return nil, message 
	end
	
	return ret
end




return x
