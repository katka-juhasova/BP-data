---------------------------------
--! @file PortCallBack.lua
--! @brief ポート関連のコールバック定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PortCallBack= {}
--_G["openrtm.PortCallBack"] = PortCallBack

PortCallBack.ConnectionCallback = {}
PortCallBack.ConnectionCallback.new = function()
	local obj = {}
	function obj:call(profile)
		
	end
	local call_func = function(self, profile)
		self:call(profile)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


PortCallBack.DisconnectCallback = {}
PortCallBack.DisconnectCallback.new = function()
	local obj = {}
	function obj:call(connector_id)
		
	end
	local call_func = function(self, connector_id)
		self:call(connector_id)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

PortCallBack.OnWrite = {}
PortCallBack.OnWrite.new = function()
	local obj = {}
	function obj:call(value)
		
	end
	local call_func = function(self, value)
		self:call(value)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

PortCallBack.OnWriteConvert = {}
PortCallBack.OnWriteConvert.new = function()
	local obj = {}
	function obj:call(value)
		return value
	end
	local call_func = function(self, value)
		self:call(value)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


PortCallBack.OnRead = {}
PortCallBack.OnRead.new = function()
	local obj = {}
	function obj:call()
		
	end
	local call_func = function(self)
		self:call()
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

PortCallBack.OnReadConvert = {}
PortCallBack.OnReadConvert.new = function()
	local obj = {}
	function obj:call(value)
		return value
	end
	local call_func = function(self, value)
		self:call(value)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



return PortCallBack
