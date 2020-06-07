---------------------------------
--! @file InPortProvider.lua
--! @brief InPortプロバイダと生成ファクトリ定義
--! Push型通信の独自インターフェース型を実装する場合は、
--! InPortProviderをメタテーブルに設定したプロバイダオブジェクトを生成する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local InPortProvider= {}
--_G["openrtm.InPortProvider"] = InPortProvider




local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory
local NVUtil = require "openrtm.NVUtil"

-- InPortプロバイダ初期化
-- @return InPortProvider
InPortProvider.new = function()
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._properties = {}
    obj._interfaceType = ""
    obj._dataflowType = ""
    obj._subscriptionType = ""
    obj._rtcout = Manager:instance():getLogbuf("InPortProvider")
    obj._connector = nil
    -- 終了関数
	function obj:exit()
	end
	-- コネクタプロファイルにインターフェース型を設定
	-- @param prop プロパティ
	function obj:publishInterfaceProfile(prop)
		self._rtcout:RTC_TRACE("publishInterfaceProfile()")
		NVUtil.appendStringValue(prop, "dataport.interface_type",
                                          self._interfaceType)
		NVUtil.append(prop, self._properties)
	end
	-- コネクタプロファイルに各種設定を行う
	-- @param prop プロパティ
	-- @return true：設定成功、false：設定失敗
	function obj:publishInterface(prop)
		self._rtcout:RTC_TRACE("publishInterface()")
		if not NVUtil.isStringValue(prop,
									"dataport.interface_type",
									self._interfaceType) then
			return false
		end
		--for i,v in ipairs(self._properties) do
		--	print(i,v)
		--end

		NVUtil.append(prop, self._properties)
		return true
	end
	-- インターフェース型の設定
	-- @param interface_type インターフェース型
	function obj:setInterfaceType(interface_type)
		self._rtcout:RTC_TRACE("setInterfaceType("..interface_type..")")
		self._interfaceType = interface_type
	end
	-- データフロー型の設定
	-- @param dataflow_type データフロー型
	function obj:setDataFlowType(dataflow_type)
		self._rtcout:RTC_TRACE("setDataFlowType("..dataflow_type..")")
		self._dataflowType = dataflow_type
	end
	-- サブスクリプション型の設定
	-- @param subs_type サブスクリプション型
	function obj:setSubscriptionType(subs_type)
		self._rtcout:RTC_TRACE("setSubscriptionType("..subs_type..")")
		self._subscriptionType = subs_type
	end
	-- コネクタ設定
	-- @param connector コネクタ
	function obj:setConnector(connector)
		self._connector = connector
	end

	return obj
end

InPortProvider.InPortProviderFactory = {}
setmetatable(InPortProvider.InPortProviderFactory, {__index=Factory.new()})

function InPortProvider.InPortProviderFactory:instance()
	return self
end


return InPortProvider
