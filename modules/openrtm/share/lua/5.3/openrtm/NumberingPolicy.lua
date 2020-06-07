---------------------------------
--! @file NumberingPolicy.lua
--! @brief 名前付けポリシー基底クラス、プロセス内の名前付けポリシー定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local NumberingPolicy= {}
--_G["openrtm.NumberingPolicy"] = NumberingPolicy

local Factory = require "openrtm.Factory"
local NumberingPolicyBase = require "openrtm.NumberingPolicyBase"
local NumberingPolicyFactory = NumberingPolicyBase.NumberingPolicyFactory
local StringUtil = require "openrtm.StringUtil"


NumberingPolicy = {}
-- 名前付けポリシー基底オブジェクト初期化
-- @return 名前付けポリシーオブジェクト
NumberingPolicy.new = function()
	local obj = {}
	function obj:onCreate(obj)
	end
	function obj:onDelete(obj)
	end
	return obj
end


NumberingPolicy.ProcessUniquePolicy = {}

-- プロセス内名前付けポリシー定義オブジェクト初期化
-- @return 名前付けポリシーオブジェクト
NumberingPolicy.ProcessUniquePolicy.new = function()
	local obj = {}
	obj._num = 0
	obj._objects = {}
	setmetatable(obj, {__index=NumberingPolicy.new()})
	-- RTCへの名前付け
	-- @param obj RTC
	-- @return 名前
	function obj:onCreate(_obj)
		self._num = self._num + 1
		local pos = self:find(nil)
		if pos < 0 then
			pos = 1
		end
		self._objects[pos] = _obj
		return StringUtil.otos(pos-1)
	end
	-- RTCの登録解除
	-- @param obj RTC
	function obj:onDelete(_obj)
		local pos = self:find(_obj)
		if pos >= 0 then
			self._objects[pos] = nil
			self._num = self._num - 1
		end
	end
	-- RTCの番号取得
	-- @param obj RTC
	-- @return 番号
	function obj:find(_obj)
		for i = 1, #self._objects + 1 do
			local obj_ = self._objects[i]
			if obj_ == _obj then
				return i
			end
		end
		return -1
	end
	return obj
end

-- プロセス内名前付けポリシー生成ファクトリ登録
NumberingPolicy.ProcessUniquePolicy.Init = function()
	NumberingPolicyFactory:instance():addFactory("process_unique",
		NumberingPolicy.ProcessUniquePolicy.new,
		Factory.Delete)
end


return NumberingPolicy
