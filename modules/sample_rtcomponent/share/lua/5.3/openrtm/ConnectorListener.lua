---------------------------------
--! @file ConnectorListener.lua
--! @brief コネクタコールバック定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ConnectorListener= {}
--_G["openrtm.ConnectorListener"] = ConnectorListener


ConnectorListener.ConnectorListenerStatus = {
	NO_CHANGE                 = 1,
	INFO_CHANGED              = 2,
	DATA_CHANGED              = 3,
	BOTH_CHANGED              = 4
}


ConnectorListener.ConnectorDataListenerType = {
	ON_BUFFER_WRITE              = 1,
	ON_BUFFER_FULL               = 2,
	ON_BUFFER_WRITE_TIMEOUT      = 3,
	ON_BUFFER_OVERWRITE          = 4,
	ON_BUFFER_READ               = 5,
	ON_SEND                      = 6,
	ON_RECEIVED                  = 7,
	ON_RECEIVER_FULL             = 8,
	ON_RECEIVER_TIMEOUT          = 9,
	ON_RECEIVER_ERROR            = 10,
	CONNECTOR_DATA_LISTENER_NUM  = 11
}



ConnectorListener.ConnectorDataListener = {}




ConnectorListener.ConnectorDataListener.toString = function(_type)
	local typeString = {"ON_BUFFER_WRITE",
						"ON_BUFFER_FULL",
						"ON_BUFFER_WRITE_TIMEOUT",
						"ON_BUFFER_OVERWRITE",
						"ON_BUFFER_READ", 
						"ON_SEND", 
						"ON_RECEIVED",
						"ON_RECEIVER_FULL", 
						"ON_RECEIVER_TIMEOUT", 
						"ON_RECEIVER_ERROR",
						"CONNECTOR_DATA_LISTENER_NUM"}

	if _type < ConnectorListener.ConnectorDataListenerType.CONNECTOR_DATA_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ConnectorListener.ConnectorDataListener.new = function()
	local obj = {}
	function obj:call(info, data)
		
	end

	function obj:__call__(info, cdrdata, dataType)
		local Manager = require "openrtm.Manager"
		local _data = Manager:instance():cdrUnmarshal(cdrdata, dataType)
		return _data
	end

	local call_func = function(self, info, data)
		self:call(info, data)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

--[[
ConnectorListener.ConnectorDataListenerT = {}
ConnectorListener.ConnectorDataListenerT.new = function()
	local obj = {}
	function obj:__call__(info, cdrdata, dataType)
		local Manager = require "openrtm.Manager"
		local _data = Manager:instance():cdrUnmarshal(cdrdata, dataType)
		return _data	
	end
	local call_func = function(self, info, cdrdata, data)
		self:call(info, cdrdata, data)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end
]]



ConnectorListener.ConnectorListenerType = {
	ON_BUFFER_EMPTY        = 1,
  	ON_BUFFER_READ_TIMEOUT = 2,
  	ON_SENDER_EMPTY        = 3,
  	ON_SENDER_TIMEOUT      = 4,
  	ON_SENDER_ERROR        = 5,
  	ON_CONNECT             = 6,
  	ON_DISCONNECT          = 7,
  	CONNECTOR_LISTENER_NUM = 8
}



ConnectorListener.ConnectorListener = {}




ConnectorListener.ConnectorListener.toString = function(_type)
	local typeString = {"ON_BUFFER_EMPTY",
						"ON_BUFFER_READ_TIMEOUT",
						"ON_SENDER_EMPTY", 
						"ON_SENDER_TIMEOUT", 
						"ON_SENDER_ERROR", 
						"ON_CONNECT",
						"ON_DISCONNECT",
						"CONNECTOR_LISTENER_NUM"}

	if _type < ConnectorListener.ConnectorListenerType.CONNECTOR_LISTENER_NUM then
		return typeString[_type]
	end
	return ""
end


ConnectorListener.ConnectorListener.new = function()
	local obj = {}
	function obj:call(info)
		
	end
	local call_func = function(self, info)
		self:call(info)
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

ConnectorListener.ConnectorDataListenerHolder = {}
ConnectorListener.ConnectorDataListenerHolder.new = function()
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
	function obj:notify(info, cdrdata)
		--print(cdrdata)
		local ret = ConnectorListener.ConnectorListenerStatus.NO_CHANGE
		for i, listener in ipairs(self._listeners) do
			ret = listener.listener:call(info, cdrdata)
		end
		return ret
	end
	return obj
end



ConnectorListener.ConnectorListenerHolder = {}
ConnectorListener.ConnectorListenerHolder.new = function()
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
	function obj:notify(info)
		local ret = ConnectorListener.ConnectorListenerStatus.NO_CHANGE
		for i, listener in ipairs(self._listeners) do
			ret = listener.listener:call(info)
		end
		return ret
	end
	return obj
end


ConnectorListener.ConnectorListeners = {}

ConnectorListener.ConnectorListeners.new = function()
	local obj = {}
	obj.connector_num = ConnectorListener.ConnectorDataListenerType.CONNECTOR_DATA_LISTENER_NUM
	obj.connectorData_ = {}
	for i = 1,obj.connector_num do
		table.insert(obj.connectorData_, ConnectorListener.ConnectorDataListenerHolder.new())
	end
	obj.connector_num = ConnectorListener.ConnectorListenerType.CONNECTOR_LISTENER_NUM
	obj.connector_ = {}
	for i = 1,obj.connector_num do
		table.insert(obj.connector_, ConnectorListener.ConnectorListenerHolder.new())
	end
	return obj
end


return ConnectorListener
