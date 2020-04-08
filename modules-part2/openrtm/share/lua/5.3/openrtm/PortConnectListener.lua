---------------------------------
--! @file PortConnectListener.lua
--! @brief コネクタ関連のコールバック定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PortConnectListener= {}
--_G["openrtm.PortConnectListener"] = PortConnectListener

PortConnectListener.PortConnectListenerType = {
												ON_NOTIFY_CONNECT = 1,
												ON_NOTIFY_DISCONNECT = 2,
												ON_UNSUBSCRIBE_INTERFACES = 3,
												PORT_CONNECT_LISTENER_NUM = 4
												}



PortConnectListener.PortConnectListener = {}




PortConnectListener.PortConnectListener.toString = function(_type)
	local typeString = {"ON_NOTIFY_CONNECT",
						"ON_NOTIFY_DISCONNECT",
						"ON_UNSUBSCRIBE_INTERFACES",
						"PORT_CONNECT_LISTENER_NUM"}

	if _type < PortConnectListener.PortConnectListenerType.PORT_CONNECT_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end

PortConnectListener.PortConnectListener.new = function()
	local obj = {}
	function obj:call(portname, profile)
		
	end



	local call_func = function(self, portname, profile)
		self:call(info, data)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



PortConnectListener.PortConnectRetListenerType = {
												ON_PUBLISH_INTERFACES = 1,
												ON_CONNECT_NEXTPORT = 2,
												ON_SUBSCRIBE_INTERFACES = 3,
												ON_CONNECTED = 4,
												ON_DISCONNECT_NEXT = 5,
												ON_DISCONNECTED = 6,
												PORT_CONNECT_RET_LISTENER_NUM = 7
												}






PortConnectListener.PortConnectRetListener = {}




PortConnectListener.PortConnectRetListener.toString = function(_type)
	local typeString = {"ON_PUBLISH_INTERFACES",
						"ON_CONNECT_NEXTPORT",
						"ON_SUBSCRIBE_INTERFACES",
						"ON_CONNECTED",
						"ON_DISCONNECT_NEXT",
						"ON_DISCONNECTED"}

	if _type < PortConnectListener.PortConnectRetListenerType.PORT_CONNECT_RET_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end

PortConnectListener.PortConnectRetListener.new = function()
	local obj = {}
	function obj:call(portname, profile, ret)
		
	end



	local call_func = function(self, portname, profile, ret)
		self:call(portname, profile, ret)
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




PortConnectListener.PortConnectListenerHolder = {}
PortConnectListener.PortConnectListenerHolder.new = function()
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
	function obj:notify(portname, profile)
		for i, listener in ipairs(self._listeners) do
			listener.listener:call(portname, profile)
		end
	end
	return obj
end





PortConnectListener.PortConnectRetListenerHolder = {}
PortConnectListener.PortConnectRetListenerHolder.new = function()
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
	function obj:notify(portname, profile, ret)
		for i, listener in ipairs(self._listeners) do
			local ret = listener.listener:call(portname, profile, ret)
		end
	end
	return obj
end



PortConnectListener.PortConnectListeners = {}

PortConnectListener.PortConnectListeners.new = function()
	local obj = {}

	obj.portconnect_num = PortConnectListener.PortConnectListenerType.PORT_CONNECT_LISTENER_NUM
	obj.portconnect_ = {}
	for i = 1,obj.portconnect_num do
		table.insert(obj.portconnect_, PortConnectListener.PortConnectListenerHolder.new())
	end

	obj.portconnret_num = PortConnectListener.PortConnectRetListenerType.PORT_CONNECT_RET_LISTENER_NUM
	obj.portconnret_ = {}
	for i = 1,obj.portconnret_num do
		table.insert(obj.portconnret_, PortConnectListener.PortConnectRetListenerHolder.new())
	end


	return obj
end




return PortConnectListener
