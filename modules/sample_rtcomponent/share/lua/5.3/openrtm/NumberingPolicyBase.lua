---------------------------------
--! @file NumberingPolicyBase.lua
--! @brief 名前付けポリシー生成ファクトリの定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local NumberingPolicyBase= {}
--_G["openrtm.NumberingPolicyBase"] = NumberingPolicyBase

local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory

NumberingPolicyBase.new = function()
	local obj = {}
	function obj:onCreate(object)
	end
	function obj:onDelete(object)
	end
	return obj
end


NumberingPolicyBase.NumberingPolicyFactory = {}
setmetatable(NumberingPolicyBase.NumberingPolicyFactory, {__index=Factory.new()})

function NumberingPolicyBase.NumberingPolicyFactory:instance()
	return self
end

return NumberingPolicyBase
