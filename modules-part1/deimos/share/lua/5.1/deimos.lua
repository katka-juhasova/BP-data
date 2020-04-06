#!/usr/local/bin/lua


---
-- This is the Deimos strong-typing library.
--
-- Deimos is a class system that uses metaprogramming to enforce strong
-- type constraints. The intended use is for validating configuration
-- files, untrusted user input, business objects that backend to
-- databases, web forms, and the like.
--
-- Odds are it can be easily abused into a true class system like LOOP
-- or Coat; however this isn't recommend as performance was never a 
-- serious consideration.
--


local class = require "deimos/class"
local array = require "deimos/array"
local hash = require "deimos/hash"

local utility = require "deimos/utility"


local x = {}



---
-- A type permitted to be anything, including nil. It imposes
-- no constraints and thus acts exactly like any other lua 
-- variable, although you can set a default value.
--
-- The default value is nil unless specified.
--
-- @param default The default value when this field is initalized.
--
function x.any( data )

	local ret = {
		ltype = 'any',
		default = data.default or nil,
		nullable = true,
		
		-- anything is permissible for 'any'
		validate = function( self, data ) end
	}
	
	function ret.default()
		return data.default or nil
	end
	
	return ret
	
end


---
-- A type permitted to be a string. It can be nullable or not;
-- have a maximum length; or be forced to pass a pattern match.
--
-- @param default The default value of this field. 
--			Normally nil if nullable, or the null string "" if not.
--
-- @param nullable If true, this field can be set to nil. Default false.
--
-- @param pattern A regular expression pattern that a set value must
--			match in order for the set to suceed. Default, not pattern
--			is enforced.
--
-- @param max_length The maximum length, as determined by string.len,
--			that this field can be set to.
--
function x.string( data )

	local ret = {
		ltype = 'string',
		nullable = data.nullable or false,
		pattern = data.pattern or ".*",
		default = data.default or true_default,
		max_length = data.max_length or nil
	}
	
	function ret.default()
		if data.default then
			return data.default
		end
	
		if data.nullable then
			return nil
		end
		
		return ""
	end
	
	function ret.validate( self, data )
		-- Prevent nullable getting this far
		if ret.nullable and (not data) then
			return
		end
	
		assert(
			type(data) == "string",
			"Type set to incorrect type " .. type(data)
		)
	
		-- Check pattern constraint
		assert(
			string.match(data, ret.pattern), 
			"String does not match pattern"
		)
		
		-- Check length constraint
		if ret.max_length then
			assert(
				string.len(data) <= ret.max_length,
				"String exceeds maximum size"
			)
		end
	end

	return ret

end


---
-- A type containing a number, either integer or floating point.
--
-- @param default The default value of this field. 
--			Normally nil if nullable, or zero if not.
--
-- @param nullable If true, this field can be set to nil. Default false.
--
-- @param maximum The maximum value this field can be set to.
--
-- @param minimum The minimum value this field can be set to.
--
function x.number( data )

	local ret = {
		ltype = 'number',
		nullable = data.nullable or false,
		maximum = data.maximum or nil,
		minimum = data.minimum or nil
	}
	
	function ret.default()	
		if data.default then
			return data.default
		end
		
		if data.nullable then
			return nil
		end
		
		return 0
	end
	
	function ret.validate( self, data )
	
		-- is it actually a number?
		assert(
			data == tonumber(data),
			"This doesn't look like a number."
			)
	
		-- Prevent nullable getting this far
		if ret.nullable and (not data) then
			return
		end
		
		if ret.maximum then
			assert( data <= ret.maximum, "Max value exceeded" )
		end
		
		if ret.minimum then
			assert( data >= ret.minimum, "Value below minimum" )
		end
	end
	
	return ret
	
end


---
-- A boolean type.
--
-- There isn't much to say or do with these, considering that they
-- by definition only have two states. In addition, Lua's handling
-- of them is pretty good already.
--
-- This exists purely to allow definition in other larger types.
--
-- @param default The default value, true or false. Defaults to false.
--
function x.bool( data )

	return {
		ltype = 'bool',
		default = data.default or false,
		
		nullable = true, 	-- the Lua idiom of nil == false caused
							-- pain. We'll find a better solution later,
							-- with nullable booleans. 
							--
							-- database-like tri-state logic in Lua is
							-- going to be interesting at best...
		
		validate = function( self, data ) 
		
				assert(
					"boolean" == type(data),
					"This isn't a boolean."
				)

			end,
			
		default = function() 
				return data.default 
			end
		}

end


---
-- Table type 'class'.
--
-- A 'class' table acts like a table with a fixed set of
-- key/value pairs that are valid; and each parameter may have
-- a forced type as well.
--
-- Simply add functions and it behaves much like an object, except
-- it lacks inheritance.
--
-- Actual methods for the type are contained in deimos/class.lua.
--
-- @param data Key/value pairs that correspond to a field's name, and
-- 			a type as provided by other Deimos constructor functions.
--
function x.class( data )
	
	local ret = {
		id = "class-" .. math.random(),
		ltype = 'class',
		schema = data
		}
		
	return utility.merge( ret, class )

end


---
-- Table type 'array'.
--
-- An 'array' table stays integer-indexed and enforces type
-- constraints on the values within.
--
-- Actual methods for the type are contained in deimos/array.lua.
--
-- @param permitted The permitted data type that can be contained
--			within the array, as provided by a deimos constructor
--			function.
--
function x.array( data )

	local ret = {
		id = "array-" .. math.random(),
		ltype = 'array',
		schema = data
		}
		
	return utility.merge( ret, array )

end


---
-- Table type 'hash'.
--
-- An 'hash' type uses key-value pairs, like a Perl hashtable or
-- PHP associative array. It enforces constraints on both the
-- keys and the values within.
--
-- Actual methods for the type are contained in deimos/hash.lua.
--
-- @param key The data type permitted to be the key of a hash,
--			as provided by a deimos constructor function.
--
-- @param value The permitted data type that can be contained
--			within the hash, as provided by a deimos constructor
--			function.
--
function x.hash( data )

	local ret = {
		id = "hash-" .. math.random(),
		ltype = 'hash',
		schema = data
		}
		
	return utility.merge( ret, hash )

end



---
--
-- Contains the version number of the library.
--
x.version = "1.0 2012.1016"


return x
