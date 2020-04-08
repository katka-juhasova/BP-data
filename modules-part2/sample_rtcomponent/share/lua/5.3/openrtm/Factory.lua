---------------------------------
--! @file Factory.lua
--! @brief RTC生成ファクトリ定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local Factory= {}
--_G["openrtm.Factory"] = Factory

local oil = require "oil"


-- RTC削除関数
-- @param rtc RTC
Factory.Delete = function(rtc)
end

Factory.FactoryBase = {}

-- RTC生成ファクトリ基底オブジェクト初期化
-- @param profile RTCのプロファイル
-- @return RTC生成ファクトリ
Factory.FactoryBase.new = function(profile)
	local obj = {}
	-- 初期化に呼ばれる関数
	function obj:init()
		self._Profile = profile
		self._Number = -1
	end
	-- RTCの生成
	-- @param mgr マネージャ
	-- @return RTC
	function obj:create(mgr)
	end
	-- RTCの削除
	-- @param mgr マネージャ
	function obj:destroy(mgr)
	end
	-- プロファイル取得
	-- @return プロファイル
	function obj:profile()
		return self._Profile
	end
	-- RTCの数取得
	-- RTC数
	function obj:number()
		return self._Number
	end


	obj:init()
	return obj
end



Factory.FactoryLua = {}

-- RTC生成ファクトリ初期化
-- @param profile RTCのプロファイル
-- @param new_func 生成関数
-- @param delete_func 削除関数
-- @param policy 番号付けポリシー
-- @return RTC生成ファクトリ
Factory.FactoryLua.new = function(profile, new_func, delete_func, policy)
	local obj = {}
	setmetatable(obj, {__index=Factory.FactoryBase.new(profile)})
	-- 初期化時に呼び出される関数
	function obj:init()
		if policy == nil then
			local NumberingPolicy = require "openrtm.NumberingPolicy"
			self._policy = NumberingPolicy.ProcessUniquePolicy.new()
		else
			self._policy = policy
		end
		self._New = new_func
		self._Delete = delete_func
	end
	-- RTC生成
	-- 生成するたびにカウントアップする
	-- RTCを削除した場合は、削除済みの番号に割り当てる
	-- @param mgr マネージャ
	-- @return RTC
	function obj:create(mgr)
		local ret = nil
		local success, exception = oil.pcall(
			function()
				--print(mgr)
				local rtobj = self._New(mgr)
				if rtobj == nil then
					return nil
				end
				self._Number = self._Number + 1
				rtobj:setProperties(self:profile())
				local instance_name = rtobj:getTypeName()
				local instance_name = instance_name..self._policy:onCreate(rtobj)
				rtobj:setInstanceName(instance_name)
				ret = rtobj
			end)
		if not success then
			print(exception)
		end
		return ret
	end
	-- RTC削除
	-- @param mgr マネージャ
	function obj:destroy(comp)
		self._Number = self._Number - 1
		self._policy:onDelete(comp)
		self._Delete(comp)
	end



	obj:init()
	return obj
end



return Factory
