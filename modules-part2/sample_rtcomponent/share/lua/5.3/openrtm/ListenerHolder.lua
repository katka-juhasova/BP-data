---------------------------------
--! @file ListenerHolder.lua
--! @brief リスナ保持クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ListenerHolder= {}
--_G["openrtm.ListenerHolder"] = ListenerHolder

local Entry = {}
Entry.new = function(listener, autoclean)
	local obj = {}
    obj.listener  = listener
    obj.autoclean = autoclean
	return obj
end


ListenerHolder.new = function()
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
	function obj:notify(func, ...)
		for i, listener in ipairs(self._listeners) do
			listener.listener[func](listener.listener, ...)
		end
		
	end
	return obj
end


return ListenerHolder
