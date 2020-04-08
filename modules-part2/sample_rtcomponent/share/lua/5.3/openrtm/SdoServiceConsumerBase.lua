---------------------------------
--! @file SdoServiceConsumerBase.lua
--! @brief SDOサービスコンシューマ基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local SdoServiceConsumerBase= {}

local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory
--_G["openrtm.SdoServiceConsumerBase"] = SdoServiceConsumerBase

SdoServiceConsumerBase.new = function()
	local obj = {}
	function obj:init(rtobj, profile)
	end
	function obj:reinit(profile)
	end
	function obj:getProfile()
	end
	function obj:finalize()
	end

	return obj
end


SdoServiceConsumerBase.SdoServiceConsumerFactory = {}
setmetatable(SdoServiceConsumerBase.SdoServiceConsumerFactory, {__index=Factory.new()})

function SdoServiceConsumerBase.SdoServiceConsumerFactory:instance()
	return self
end

return SdoServiceConsumerBase
