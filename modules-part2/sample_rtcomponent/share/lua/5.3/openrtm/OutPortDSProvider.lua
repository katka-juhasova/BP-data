---------------------------------
--! @file OutPortDSProvider.lua
--! @brief CorbaCdrインターフェースで通信するOutPortProvider定義
--! 「data_service」のインターフェース型で利用可能
--! RTC.idlのPortServiceインターフェース
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortDSProvider= {}
--_G["openrtm.OutPortDSProvider"] = OutPortDSProvider

local OutPortProvider = require "openrtm.OutPortProvider"
local BufferStatus = require "openrtm.BufferStatus"

local Factory = require "openrtm.Factory"
local OutPortProviderFactory = OutPortProvider.OutPortProviderFactory

local RTCUtil = require "openrtm.RTCUtil"

local NVUtil = require "openrtm.NVUtil"

local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorListenerType = ConnectorListener.ConnectorListenerType
local ConnectorDataListenerType = ConnectorListener.ConnectorDataListenerType


-- CorbaCdrインターフェースのOutPortProviderオブジェクト初期化
-- @return CorbaCdrインターフェースのOutPortProviderオブジェクト
OutPortDSProvider.new = function()
	local obj = {}
	setmetatable(obj, {__index=OutPortProvider.new()})
	local Manager = require "openrtm.Manager"
	obj._PortStatus = Manager:instance():getORB().types:lookup("::RTC::PortStatus").labelvalue


	obj:setInterfaceType("data_service")
	obj._buffer = nil

	local orb = Manager:instance():getORB()
	obj._svr = orb:newservant(obj, nil, "IDL:omg.org/RTC/DataPullService:1.0")
	local str = orb:tostring(obj._svr)
	obj._objref = RTCUtil.getReference(orb, obj._svr, "IDL:omg.org/RTC/DataPullService:1.0")

	table.insert(obj._properties, NVUtil.newNV("dataport.data_service.outport_ior",
													str))
    --table.insert(obj._properties, NVUtil.newNV("dataport.data_service.outport_ref",
	--												obj._objref))

	obj._listeners = nil
    obj._connector = nil
    obj._profile   = nil

	-- 終了処理
	function obj:exit()
		Manager:instance():getORB():deactivate(self._svr)
	end

	-- 初期化時にプロパティ設定
	-- @param prop プロパティ
	function obj:init(prop)
	end

    -- バッファ設定
    -- @param buffer バッファ
	function obj:setBuffer(buffer)
		self._buffer = buffer
	end

	-- コールバック関数設定
	-- @param info プロファイル
	-- @param listeners コールバック関数
	function obj:setListener(info, listeners)
		self._profile = info
		self._listeners = listeners
	end

	-- コネクタ設定
	-- @param connector コネクタ
	function obj:setConnector(connector)
		self._connector = connector
	end

    -- データ読み込み
    -- @return リターンコード、データ
    -- PORT_OK：正常終了
    -- PORT_ERROR：バッファがない
    -- BUFFER_EMPTY：バッファが空
    -- その他、バッファフル、タイムアウト等の戻り値
	function obj:pull()
		self._rtcout:RTC_PARANOID("OutPortDSProvider.get()")
		if self._buffer == nil then
			self:onSenderError()
			return self._PortStatus.UNKNOWN_ERROR, ""
		end


		if self._buffer:empty() then
			self._rtcout:RTC_ERROR("buffer is empty.")
			return self._PortStatus.BUFFER_EMPTY, ""
		end

		local cdr = {_data=""}
		local ret = self._buffer:read(cdr)

		if ret == BufferStatus.BUFFER_OK then
			if cdr._data == "" then
				self._rtcout:RTC_ERROR("buffer is empty.")
				return self._PortStatus.BUFFER_EMPTY, ""
			end
		end
		return self:convertReturn(ret, cdr._data)
	end

	-- バッファ書き込み時コールバック
	-- @param data データ
	function obj:onBufferRead(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_BUFFER_READ]:notify(self._profile, data)
		end
    end

    -- データ送信時コールバック
	-- @param data データ
	function obj:onSend(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_SEND]:notify(self._profile, data)
		end
    end

    -- バッファ空時コールバック
	function obj:onBufferEmpty()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_BUFFER_EMPTY]:notify(self._profile)
		end
    end
    -- バッファ読み込みタイムアウト時コールバック
	function obj:onBufferReadTimeout()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_BUFFER_READ_TIMEOUT]:notify(self._profile)
		end
    end
    -- 送信データ空時コールバック
	function obj:onSenderEmpty()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_SENDER_EMPTY]:notify(self._profile)
		end
    end
    -- データ送信タイムアウト時コールバック
	function obj:onSenderTimeout()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_SENDER_TIMEOUT]:notify(self._profile)
		end
    end
	-- データ送信エラー時コールバック
	function obj:onSenderError()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_SENDER_ERROR]:notify(self._profile)
		end
    end
	-- バッファステータスをRTC::PortStatusに変換
	--コールバック呼び出し
	-- @param status バッファステータス
	-- @param data データ
	-- @param ポートステータス、データ
	function obj:convertReturn(status, data)
		if status == BufferStatus.BUFFER_OK then
			self:onBufferRead(data)
			self:onSend(data)
			return self._PortStatus.PORT_OK, data
		elseif status == BufferStatus.BUFFER_ERROR then
			self:onSenderError()
			return self._PortStatus.PORT_ERROR, data
		elseif status == BufferStatus.BUFFER_FULL then
		  return self._PortStatus.BUFFER_FULL, data
		elseif status == BufferStatus.BUFFER_EMPTY then
			self:onBufferEmpty()
			self:onSenderEmpty()
			return self._PortStatus.BUFFER_EMPTY, data
		elseif status == BufferStatus.PRECONDITION_NOT_MET then
			self:onSenderError()
			return self._PortStatus.PORT_ERROR, data
		elseif status == BufferStatus.TIMEOUT then
			self:onBufferReadTimeout()
			self:onSenderTimeout()
			return self._PortStatus.BUFFER_TIMEOUT, data
		else
			return self._PortStatus.UNKNOWN_ERROR, data
		end
	end
	function obj:getObjRef()
		return self._objref
	end




	return obj
end

-- OutPortDSProvider生成ファクトリ登録関数
OutPortDSProvider.Init = function()
	OutPortProviderFactory:instance():addFactory("data_service",
		OutPortDSProvider.new,
		Factory.Delete)
end


return OutPortDSProvider
