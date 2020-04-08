---------------------------------
--! @file PublisherNew.lua
--! @brief 別スレッドでデータを送信するパブリッシャ定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PublisherNew= {}
--_G["openrtm.PublisherNew"] = PublisherNew

PublisherNew.new = function()
	local obj = {}
	return obj
end


return PublisherNew
