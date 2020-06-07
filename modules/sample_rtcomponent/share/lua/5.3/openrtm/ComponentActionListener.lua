---------------------------------
--! @file ComponentActionListener.lua
--! @brief コンポーネントコールバック定義クラス
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ComponentActionListener= {}
--_G["openrtm.ComponentActionListener"] = ComponentActionListener


ComponentActionListener.PreComponentActionListenerType = {
	PRE_ON_INITIALIZE                 = 1,
	PRE_ON_FINALIZE                   = 2,
	PRE_ON_STARTUP                    = 3,
	PRE_ON_SHUTDOWN                   = 4,
	PRE_ON_ACTIVATED                  = 5,
	PRE_ON_DEACTIVATED                = 6,
	PRE_ON_ABORTING                   = 7,
	PRE_ON_ERROR                      = 8,
	PRE_ON_RESET                      = 9,
	PRE_ON_EXECUTE                    = 10,
	PRE_ON_STATE_UPDATE               = 11,
	PRE_ON_RATE_CHANGED               = 12,
	PRE_COMPONENT_ACTION_LISTENER_NUM = 13
}

ComponentActionListener.PreComponentActionListener = {}




ComponentActionListener.PreComponentActionListener.toString = function(_type)
	local typeString = {"PRE_ON_INITIALIZE",
						"PRE_ON_FINALIZE",
						"PRE_ON_STARTUP",
						"PRE_ON_SHUTDOWN",
						"PRE_ON_ACTIVATED",
						"PRE_ON_DEACTIVATED",
						"PRE_ON_ABORTING",
						"PRE_ON_ERROR",
						"PRE_ON_RESET",
						"PRE_ON_EXECUTE",
						"PRE_ON_STATE_UPDATE",
						"PRE_ON_RATE_CHANGED",
						"PRE_COMPONENT_ACTION_LISTENER_NUM"}

	if _type < ComponentActionListener.PreComponentActionListenerType.PRE_COMPONENT_ACTION_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ComponentActionListener.PreComponentActionListener.new = function()
	local obj = {}
	function obj:call(ec_id)
		
	end
	local call_func = function(self, ec_id)
		self:call(ec_id)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end





ComponentActionListener.PostComponentActionListenerType = {
	POST_ON_INITIALIZE                 = 1,
	POST_ON_FINALIZE                   = 2,
	POST_ON_STARTUP                    = 3,
	POST_ON_SHUTDOWN                   = 4,
	POST_ON_ACTIVATED                  = 5,
	POST_ON_DEACTIVATED                = 6,
	POST_ON_ABORTING                   = 7,
	POST_ON_ERROR                      = 8,
	POST_ON_RESET                      = 9,
	POST_ON_EXECUTE                    = 10,
	POST_ON_STATE_UPDATE               = 11,
	POST_ON_RATE_CHANGED               = 12,
	POST_COMPONENT_ACTION_LISTENER_NUM = 13
}


ComponentActionListener.PostComponentActionListener = {}




ComponentActionListener.PostComponentActionListener.toString = function(_type)
	local typeString = {"POST_ON_INITIALIZE",
						"POST_ON_FINALIZE",
						"POST_ON_STARTUP",
						"POST_ON_SHUTDOWN",
						"POST_ON_ACTIVATED",
						"POST_ON_DEACTIVATED",
						"POST_ON_ABORTING",
						"POST_ON_ERROR",
						"POST_ON_RESET",
						"POST_ON_EXECUTE",
						"POST_ON_STATE_UPDATE",
						"POST_ON_RATE_CHANGED",
						"POST_COMPONENT_ACTION_LISTENER_NUM"}

	if _type < ComponentActionListener.PostComponentActionListenerType.POST_COMPONENT_ACTION_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ComponentActionListener.PostComponentActionListener.new = function()
	local obj = {}
	function obj:call(ec_id, ret)
		
	end
	local call_func = function(self, ec_id, ret)
		self:call(ec_id, ret)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



ComponentActionListener.PortActionListenerType = {
	ADD_PORT                 = 1,
	REMOVE_PORT              = 2,
	PORT_ACTION_LISTENER_NUM = 3
}

ComponentActionListener.PortActionListener = {}




ComponentActionListener.PortActionListener.toString = function(_type)
	local typeString = {"ADD_PORT",
						"REMOVE_PORT",
						"PORT_ACTION_LISTENER_NUM"}

	if _type < ComponentActionListener.PortActionListenerType.PORT_ACTION_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ComponentActionListener.PortActionListener.new = function()
	local obj = {}
	function obj:call(pprof)
		
	end
	local call_func = function(self, pprof)
		self:call(pprof)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



ComponentActionListener.ExecutionContextActionListenerType = {
	EC_ATTACHED            = 1,
	EC_DETACHED            = 2,
	EC_ACTION_LISTENER_NUM = 3
}

ComponentActionListener.ExecutionContextActionListener = {}




ComponentActionListener.ExecutionContextActionListener.toString = function(_type)
	local typeString = {"EC_ATTACHED",
						"EC_DETACHED",
						"EC_ACTION_LISTENER_NUM"}

	if _type < ComponentActionListener.ExecutionContextActionListenerType.EC_ACTION_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ComponentActionListener.ExecutionContextActionListener.new = function()
	local obj = {}
	function obj:call(ec_id)
		
	end
	local call_func = function(self, ec_id)
		self:call(ec_id)
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

ComponentActionListener.PreComponentActionListenerHolder = {}
ComponentActionListener.PreComponentActionListenerHolder.new = function()
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
	function obj:notify(ec_id)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(ec_id)
		end
	end
	return obj
end


ComponentActionListener.PostComponentActionListenerHolder = {}
ComponentActionListener.PostComponentActionListenerHolder.new = function()
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
	function obj:notify(ec_id, ret)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(ec_id, ret)
		end
	end
	return obj
end

ComponentActionListener.PortActionListenerHolder = {}
ComponentActionListener.PortActionListenerHolder.new = function()
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
	function obj:notify(pprofile)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(pprofile)
		end
	end
	return obj
end



ComponentActionListener.ExecutionContextActionListenerHolder = {}
ComponentActionListener.ExecutionContextActionListenerHolder.new = function()
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
	function obj:notify(ec_id)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(ec_id)
		end
	end
	return obj
end

ComponentActionListener.ComponentActionListeners = {}
ComponentActionListener.ComponentActionListeners.new = function()
	local obj = {}
	obj.preaction_num = ComponentActionListener.PreComponentActionListenerType.PRE_COMPONENT_ACTION_LISTENER_NUM
	obj.preaction_ = {}
	for i = 1,obj.preaction_num do
		table.insert(obj.preaction_, ComponentActionListener.PreComponentActionListenerHolder.new())
	end

	obj.postaction_num = ComponentActionListener.PostComponentActionListenerType.POST_COMPONENT_ACTION_LISTENER_NUM
	obj.postaction_ = {}
	for i = 1,obj.postaction_num do
		table.insert(obj.postaction_, ComponentActionListener.PostComponentActionListenerHolder.new())
	end

	obj.portaction_num = ComponentActionListener.PortActionListenerType.PORT_ACTION_LISTENER_NUM
	obj.portaction_ = {}
	for i = 1,obj.portaction_num do
		table.insert(obj.portaction_, ComponentActionListener.PortActionListenerHolder.new())
	end

	obj.ecaction_num = ComponentActionListener.ExecutionContextActionListenerType.EC_ACTION_LISTENER_NUM
	obj.ecaction_ = {}
	for i = 1,obj.ecaction_num do
		table.insert(obj.ecaction_, ComponentActionListener.ExecutionContextActionListenerHolder.new())
	end
    
	return obj
end


return ComponentActionListener
