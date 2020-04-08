---------------------------------
--! @file ExtTrigExecutionContext.lua
--! @brief トリガ駆動実行コンテキスト定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ExtTrigExecutionContext= {}
--_G["openrtm.ExtTrigExecutionContext"] = ExtTrigExecutionContext

ExtTrigExecutionContext.new = function()
	local obj = {}
	return obj
end


return ExtTrigExecutionContext
