--- Aurora
-- Lua tool set of functions

-- @module aurora
-- @author KXMN 
-- @copyright Copyright (c) 2019 Kxmn
-- @license MIT


--- Global function loader
-- Allow methods to be autoloaded from filesystem subtree
-- @param m full module name
-- @param t current method table for "in file" methods
_G.ondemand = function(m)
		return setmetatable ({},{
			__index = function(t,k)
				return require(m..'.'..k)
			end
		})
end

return ondemand('aurora')
