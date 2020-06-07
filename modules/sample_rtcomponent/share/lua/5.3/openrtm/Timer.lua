---------------------------------
--! @file Timer.lua
--! @brief タイマ関連の関数定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local Timer= {}
--_G["openrtm.Timer"] = Timer

local oil = require "oil"

Timer.new = function()
	local obj = {}
	return obj
end

-- 一定時間待機
-- @param tm 待機時間
Timer.sleep = function(tm)
	if oil.VERSION == "OiL 0.6" then
		oil.sleep(tm)
	else
		oil.tasks:suspend(tm)
	end
end


return Timer
