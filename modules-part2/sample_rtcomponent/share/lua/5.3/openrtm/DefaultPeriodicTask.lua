---------------------------------
--! @file DefaultPeriodicTask.lua
--! @brief デフォルトの周期実行タスク
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local DefaultPeriodicTask= {}
--_G["openrtm.DefaultPeriodicTask"] = DefaultPeriodicTask

DefaultPeriodicTask.new = function()
	local obj = {}
	return obj
end


return DefaultPeriodicTask
