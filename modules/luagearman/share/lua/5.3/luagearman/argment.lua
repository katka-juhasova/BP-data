local geaman = require "luagearman.gearman"
local ffi = require "ffi"

ffi.cdef([[
	gearman_argument_t gearman_argument_make(const char *name, const size_t name_length, const char *value, const size_t value_size);
]])

local argment = {}
argment.__index = argment

---
--
function argment.init()
	local self = {
		_argment = nil
	}
	return setmetatable(self, argment)
end

---
--
function argment:make(name, value)
	local c_name = nil
	local c_name_length = 0
	if name ~= nil then
		c_name = name
		c_name_length = #name
	end

	local c_value = nil
	local c_value_length = 0
	if value ~= nil then
		c_value = value
		c_value_length = #value
	end

	self._argment = geaman.ffi.gearman_argument_make(c_name, c_name_length, c_value, c_value_length)
end

---
--
function argment:getCInstance()
	return self._argment
end

return argment