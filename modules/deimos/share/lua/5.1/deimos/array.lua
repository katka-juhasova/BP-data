#!/usr/local/bin/lua


local utility = require "deimos/utility"
local x = {}


---
-- Deimos 'array' type.
--
-- Implements an array with continguous integer keys mapped
-- to arbitrary values. Preserves order much like an array should.
--


--
-- Metamethods for the array type.
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
	
	assert(schema)
	assert(sdata)

	assert(
			type(key) == 'number',
			"Key must be an integer, not " .. tostring(key)
		)

	if not schema.permitted.nullable then
		assert(data, "Field cannot be nil: " .. tostring(key))
	end
	
	local new_data = schema.permitted:validate(data)
	
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
-- Constructs a new array type object.
--
-- @param self The schema of the array being created.
-- @return A new empty array of the defined type.
--
function x.new( self )
		
	local ret = { 
			id = self.id,
			schema = utility.clone(self.schema),
			data = {}
		}
		
		
	--
	-- We can't use the table namespace, because it doesn't trigger
	-- metamethod events like __index. The shame.
	--
	-- So... we must emulate the namespace.
	--
	function ret.insert( self, new_data, pos )
	
		ret.schema.permitted:validate( new_data )
		
		--
		-- So table.insert(t, data) turns into (t, pos, data)...
		-- WTF were they thinking with the optional arguments? That
		-- must have been a pain to implement!
		--
		
		if pos then
			return table.insert( ret.data, pos, new_data )
		end
		
		return table.insert( ret.data, new_data )
	end

	function ret.remove( self, index )
		return table.remove( ret.data, index )
	end
	
	function ret.sort( self, fcn )
		return table.sort( ret.data, fcn )
	end
	
	function ret.getn( self )
		return table.getn( ret.data )
	end
	
	function ret.ipairs( self )
		return ipairs( ret.data )
	end
		
		
	setmetatable(ret, methods)
	return ret
	
end


--
-- The default of an array is also it's constructor.
--
x.default = x.new


---
-- Tests that 'data' is an object of the same type described by
-- 'schema'.
--
-- @param self Schema object, the type being checked for
-- @param data Data object being tested.
--
-- @return Nothing, unless the object was a valid array, in which
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

	status, message = pcall( function()
			for k, v in pairs(data) do
			
				assert(
					type(k) == 'number',
					"Array key not numeric: " .. tostring(k)
				)
			
				--
				-- Newindex should validate the incoming data.
				-- 
				ret[k] = v
			end
		end)
	
	if not status then 
		return nil, message 
	end
	
	return ret
end



return x
