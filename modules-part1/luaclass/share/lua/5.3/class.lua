local object_class_obj 
object_class_obj = {
	__instance_metatable = {
		__index = object_class_obj
	}
}

function object_class_obj:new( ... )
	local instance = {}
	setmetatable(instance, self.__instance_metatable)
	self:__ctor(instance, ...)
	return instance
end

function object_class_obj:ctor( ... )
	-- body
end

function object_class_obj:__ctor( instance, ... )
	local my_ctor = rawget(self, 'ctor')
	if my_ctor then
		my_ctor(instance, ...)
	else
		instance:super_ctor()
	end
end

function object_class_obj:super_ctor( ... )
	if self.__super then
		self.__super:__ctor(self, ...)
	end
end

local class_db = {}

local function class( class_name, super_class_obj)

	assert(not class_db[class_name], '' .. class_name .. ' is already exist!!!')

	if not super_class_obj then
		super_class_obj = object_class_obj
	end

	local class_obj = {}
	class_db[class_name] = class_obj

	class_obj.__instance_metatable = {
		__index = class_obj
	}

	setmetatable(class_obj, {
		__index = super_class_obj,
	})

	class_obj.__super = super_class_obj

	return class_obj
end

return class