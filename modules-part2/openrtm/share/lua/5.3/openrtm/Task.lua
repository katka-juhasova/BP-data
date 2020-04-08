---------------------------------
--! @file Task.lua
--! @brief コルーチン実行管理関数定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local Task= {}
--_G["openrtm.Task"] = Task

local oil = require "oil"



--[[
Task.new = function(object)
	local obj = {}
	obj._instance = object

	local call_func = function(self)
		self._instance:svc()
	end
	setmetatable(obj, {__call=call_func})
	return obj
end
]]

-- コルーチンを追加する
-- @param object 実行関数オブジェクト
Task.start = function(object)
	oil.newthread(function()
					object:svc()
				end)
end



return Task
