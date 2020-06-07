---------------------------------
--! @file OutPortProvider.lua
--! @brief OutPortプロバイダと生成ファクトリ定義
--! Pull型通信の独自インターフェース型を実装する場合は、
--! OutPortProviderをメタテーブルに設定したプロバイダオブジェクトを生成する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortProvider= {}
--_G["openrtm.OutPortProvider"] = OutPortProvider

local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory
local NVUtil = require "openrtm.NVUtil"

-- OutPortプロバイダオブジェクト初期化
-- @return OutPortプロバイダオブジェクト
OutPortProvider.new = function()
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._properties = {}
    obj._portType         = ""
    obj._dataType         = ""
    obj._interfaceType    = ""
    obj._dataflowType     = ""
    obj._subscriptionType = ""
    obj._rtcout = Manager:instance():getLogbuf("OutPortProvider")

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

		NVUtil.append(prop, self._properties)
		return true
	end
	-- ポート型の設定
	-- @param port_type ポート型
	function obj:setPortType(port_type)
		self._portType = port_type
	end
	-- データ型の設定
	-- @param port_type データ型
	function obj:setDataType(data_type)
		self._dataType = data_type
	end
	-- インターフェース型の設定
	-- @param interface_type インターフェース型
	function obj:setInterfaceType(interface_type)
		self._interfaceType = interface_type
	end
	-- データフロー型の設定
	-- @param dataflow_type データフロー型
	function obj:setDataFlowType(dataflow_type)
		self._dataflowType = dataflow_type
	end
	-- サブスクリプション型の設定
	-- @param subs_type サブスクリプション型
	function obj:setSubscriptionType(subs_type)
		self._subscriptionType = subs_type
	end
	return obj
end

OutPortProvider.OutPortProviderFactory = {}
setmetatable(OutPortProvider.OutPortProviderFactory, {__index=Factory.new()})

function OutPortProvider.OutPortProviderFactory:instance()
	return self
end


return OutPortProvider
