---------------------------------
--! @file InPortDSProvider.lua
--! @brief CorbaCdrインターフェースで通信するInPortProvider定義
--! 「data_service」のインターフェース型で利用可能
--! RTC.idlのPortServiceインターフェース
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local InPortDSProvider= {}
--_G["openrtm.InPortDSProvider"] = InPortDSProvider



local oil = require "oil"
local InPortProvider = require "openrtm.InPortProvider"
local NVUtil = require "openrtm.NVUtil"
local BufferStatus = require "openrtm.BufferStatus"

local Factory = require "openrtm.Factory"
local InPortProviderFactory = InPortProvider.InPortProviderFactory
local RTCUtil = require "openrtm.RTCUtil"

local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorDataListenerType = ConnectorListener.ConnectorDataListenerType


-- CorbaCdrインターフェースのInPortProviderオブジェクト初期化
-- @return CorbaCdrインターフェースのInPortProviderオブジェクト
InPortDSProvider.new = function()
	local obj = {}
	--print(InPortProvider.new)
	setmetatable(obj, {__index=InPortProvider.new()})
	local Manager = require "openrtm.Manager"
	obj._PortStatus = Manager:instance():getORB().types:lookup("::RTC::PortStatus").labelvalue
    obj:setInterfaceType("data_service")

	local orb = Manager:instance():getORB()
	obj._svr = orb:newservant(obj, nil, "IDL:omg.org/RTC/DataPushService:1.0")
	local str = orb:tostring(obj._svr)
	obj._objref = RTCUtil.getReference(orb, obj._svr, "IDL:omg.org/RTC/DataPushService:1.0")



    obj._buffer = nil

    obj._profile = nil
    obj._listeners = nil



    table.insert(obj._properties, NVUtil.newNV("dataport.data_service.inport_ior",
													str))
    --table.insert(obj._properties, NVUtil.newNV("dataport.data_service.inport_ref",
	--												obj._objref))
	--print(obj._properties)
	--for i,v in ipairs(obj._properties) do
	--	print(i,v)
	--end

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
    -- データ書き込み
    -- @param data データ
    -- @return リターンコード
    -- PORT_OK：正常終了
    -- PORT_ERROR：バッファがない
    -- UNKNOWN_ERROR：復号化失敗など、その他のエラー
    -- その他、バッファフル、タイムアウト等の戻り値
	function obj:push(data)
		--print("put")
		local status = self._PortStatus.PORT_OK
		local success, exception = oil.pcall(
			function()
				self._rtcout:RTC_PARANOID("InPortDSProvider.put()")

				--[[
				if self._buffer == nil then
					self:onReceiverError(data)
					return self._PortStatus.PORT_ERROR
				end
				--]]

				self._rtcout:RTC_PARANOID("received data size: "..#data)

				self:onReceived(data)
				--print(self._connector)
				if self._connector == nil then
					status = self._PortStatus.PORT_ERROR
					return
				end
				--print("test,",data)
				local ret = self._connector:write(data)

				status = self:convertReturn(ret, data)
			end)

		if not success then
			self._rtcout:RTC_TRACE(exception)
			return self._PortStatus.UNKNOWN_ERROR
		end
		return status
	end
	-- バッファステータスをOpenRTM::PortStatusに変換
	--コールバック呼び出し
	-- @param status バッファステータス
	-- @param data データ
	-- @param ポートステータス
	function obj:convertReturn(status, data)
		if status == BufferStatus.BUFFER_OK then
			self:onBufferWrite(data)
			return self._PortStatus.PORT_OK

		elseif status == BufferStatus.BUFFER_ERROR then
			self:onReceiverError(data)
			return self._PortStatus.PORT_ERROR

		elseif status == BufferStatus.BUFFER_FULL then
			self:onBufferFull(data)
			self:onReceiverFull(data)
			return self._PortStatus.BUFFER_FULL

		elseif status == BufferStatus.BUFFER_EMPTY then
			return self._PortStatus.BUFFER_EMPTY

		elseif status == BufferStatus.PRECONDITION_NOT_MET then
			self:onReceiverError(data)
			return self._PortStatus.PORT_ERROR

		elseif status == BufferStatus.TIMEOUT then
			self:onBufferWriteTimeout(data)
			self:onReceiverTimeout(data)
			return self._PortStatus.BUFFER_TIMEOUT

		else
			self:onReceiverError(data)
			return self._PortStatus.UNKNOWN_ERROR
		end
	end
	-- バッファ書き込み時コールバック
	-- @param data データ
	function obj:onBufferWrite(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_BUFFER_WRITE]:notify(self._profile, data)
		end
    end
    -- バッファフル時コールバック
	-- @param data データ
	function obj:onBufferFull(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_BUFFER_FULL]:notify(self._profile, data)
		end
    end
    -- バッファ書き込みタイムアウト時コールバック
	-- @param data データ
	function obj:onBufferWriteTimeout(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_BUFFER_WRITE_TIMEOUT]:notify(self._profile, data)
		end
    end
    -- バッファ上書き時コールバック
	-- @param data データ
	function obj:onBufferWriteOverwrite(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_BUFFER_OVERWRITE]:notify(self._profile, data)
		end
    end
    -- 受信時コールバック
	-- @param data データ
	function obj:onReceived(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVED]:notify(self._profile, data)
		end
    end
    -- 受信バッファフル時コールバック
	-- @param data データ
	function obj:onReceiverFull(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVER_FULL]:notify(self._profile, data)
		end
    end
    -- 受信タイムアウト時コールバック
	-- @param data データ
	function obj:onReceiverTimeout(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVER_TIMEOUT]:notify(self._profile, data)
		end
    end
    -- 受信エラー時コールバック
	-- @param data データ
	function obj:onReceiverError(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVER_ERROR]:notify(self._profile, data)
		end
	end
	function obj:getObjRef()
		return self._objref
	end
	return obj
end

-- InPortDSProvider生成ファクトリ登録関数
InPortDSProvider.Init = function()
	InPortProviderFactory:instance():addFactory("data_service",
		InPortDSProvider.new,
		Factory.Delete)
end


return InPortDSProvider
