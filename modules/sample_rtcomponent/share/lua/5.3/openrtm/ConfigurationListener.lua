---------------------------------
--! @file ConfigurationListener.lua
--! @brief コンフィギュレーションコールバック定義クラス
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ConfigurationListener= {}
--_G["openrtm.ConfigurationListener"] = ConfigurationListener

ConfigurationListener.ConfigurationParamListenerType = {
	ON_UPDATE_CONFIG_PARAM      = 1,
	CONFIG_PARAM_LISTENER_NUM   = 2
}


ConfigurationListener.ConfigurationParamListener = {}




ConfigurationListener.ConfigurationParamListener.toString = function(_type)
	local typeString = {"ON_UPDATE_CONFIG_PARAM",
						"CONFIG_PARAM_LISTENER_NUM"}

	if _type < ConfigurationListener.ConfigurationParamListenerType.CONFIG_PARAM_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ConfigurationListener.ConfigurationParamListener.new = function()
	local obj = {}
	function obj:call(config_set_name, config_param_name)
		
	end


	local call_func = function(self, config_set_name, config_param_name)
		self:call(config_set_name, config_param_name)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end





ConfigurationListener.ConfigurationSetListenerType = {
	ON_SET_CONFIG_SET       = 1,
	ON_ADD_CONFIG_SET       = 2,
	CONFIG_SET_LISTENER_NUM = 3
}


ConfigurationListener.ConfigurationSetListener = {}




ConfigurationListener.ConfigurationSetListener.toString = function(_type)
	local typeString = {"ON_SET_CONFIG_SET",
						"ON_ADD_CONFIG_SET",
						"CONFIG_SET_LISTENER_NUM"}

	if _type < ConfigurationListener.ConfigurationSetListenerType.CONFIG_SET_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ConfigurationListener.ConfigurationSetListener.new = function()
	local obj = {}
	function obj:call(config_set)
		
	end


	local call_func = function(self, config_set)
		self:call(config_set)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end





ConfigurationListener.ConfigurationSetNameListenerType = {
	ON_UPDATE_CONFIG_SET         = 1,
	ON_REMOVE_CONFIG_SET         = 2,
	ON_ACTIVATE_CONFIG_SET       = 3,
	CONFIG_SET_NAME_LISTENER_NUM = 4
}


ConfigurationListener.ConfigurationSetNameListener = {}




ConfigurationListener.ConfigurationSetNameListener.toString = function(_type)
	local typeString = {"ON_UPDATE_CONFIG_SET",
						"ON_REMOVE_CONFIG_SET",
						"ON_ACTIVATE_CONFIG_SET",
						"CONFIG_SET_NAME_LISTENER_NUM"}

	if _type < ConfigurationListener.ConfigurationSetNameListenerType.CONFIG_SET_NAME_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ConfigurationListener.ConfigurationSetNameListener.new = function()
	local obj = {}
	function obj:call(config_set_name)
		
	end


	local call_func = function(self, config_set_name)
		self:call(config_set_name)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



local Entry = {}
Entry.new = function(listener, autoclean)
	local obj = {}
    obj.listener  = listener
    obj.autoclean = autoclean
	return obj
end



ConfigurationListener.ConfigurationParamListenerHolder = {}
ConfigurationListener.ConfigurationParamListenerHolder.new = function()
	local obj = {}
	obj._listeners = {}
	function obj:addListener(listener, autoclean)
		table.insert(self._listeners, Entry.new(listener, autoclean))
	end
	function obj:removeListener(listener)
		for i,_listener in ipairs(self._listeners) do
			if _listener.listener == listener then
				if _listener.autoclean then
					table.remove(self._listeners, i)
				end
			end
		end
	end
	function obj:notify(config_set_name, config_param_name)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(config_set_name, config_param_name)
		end
		
	end
	return obj
end



ConfigurationListener.ConfigurationSetListenerHolder = {}
ConfigurationListener.ConfigurationSetListenerHolder.new = function()
	local obj = {}
	obj._listeners = {}
	function obj:addListener(listener, autoclean)
		table.insert(self._listeners, Entry.new(listener, autoclean))
	end
	function obj:removeListener(listener)
		for i,_listener in ipairs(self._listeners) do
			if _listener.listener == listener then
				if _listener.autoclean then
					table.remove(self._listeners, i)
				end
			end
		end
	end
	function obj:notify(config_set)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(config_set)
		end
		
	end
	
	return obj
end




ConfigurationListener.ConfigurationSetNameListenerHolder = {}
ConfigurationListener.ConfigurationSetNameListenerHolder.new = function()
	local obj = {}
	obj._listeners = {}
	function obj:addListener(listener, autoclean)
		table.insert(self._listeners, Entry.new(listener, autoclean))
	end
	function obj:removeListener(listener)
		for i,_listener in ipairs(self._listeners) do
			if _listener.listener == listener then
				if _listener.autoclean then
					table.remove(self._listeners, i)
				end
			end
		end
	end
	function obj:notify(config_set_name)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(config_set_name)
		end
		
	end
	
	return obj
end


ConfigurationListener.ConfigurationListeners = {}
ConfigurationListener.ConfigurationListeners.new = function()
	local obj = {}
	obj.configparam_num = ConfigurationListener.ConfigurationParamListenerType.CONFIG_PARAM_LISTENER_NUM
	obj.configparam_ = {}
	for i = 1,obj.configparam_num do
		table.insert(obj.configparam_, ConfigurationListener.ConfigurationParamListenerHolder.new())
	end
	obj.configset_num = ConfigurationListener.ConfigurationSetListenerType.CONFIG_SET_LISTENER_NUM
	obj.configset_ = {}
	for i = 1,obj.configset_num do
		table.insert(obj.configset_, ConfigurationListener.ConfigurationSetListenerHolder.new())
	end
	obj.configsetname_num = ConfigurationListener.ConfigurationSetNameListenerType.CONFIG_SET_NAME_LISTENER_NUM
	obj.configsetname_ = {}
	for i = 1,obj.configsetname_num do
		table.insert(obj.configsetname_, ConfigurationListener.ConfigurationSetNameListenerHolder.new())
	end
	return obj
end


return ConfigurationListener
