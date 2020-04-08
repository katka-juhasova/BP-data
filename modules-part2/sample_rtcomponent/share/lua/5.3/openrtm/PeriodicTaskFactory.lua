---------------------------------
--! @file PeriodicTaskFactory.lua
--! @brief 周期実行タスク生成ファクトリ定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PeriodicTaskFactory= {}
--_G["openrtm.PeriodicTaskFactory"] = PeriodicTaskFactory

PeriodicTaskFactory.new = function()
	local obj = {}
	return obj
end


return PeriodicTaskFactory
