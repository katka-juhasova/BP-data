---------------------------------
--! @file PeriodicTask.lua
--! @brief 周期実行タスク定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PeriodicTask= {}
--_G["openrtm.PeriodicTask"] = PeriodicTask

PeriodicTask.new = function()
	local obj = {}
	return obj
end


return PeriodicTask
