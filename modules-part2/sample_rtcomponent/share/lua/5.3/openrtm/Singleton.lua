---------------------------------
--! @file Singleton.lua
--! @brief シングルトン定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local Singleton= {}
--_G["openrtm.Singleton"] = Singleton

Singleton.new = function()
	local obj = {}
	return obj
end


return Singleton
