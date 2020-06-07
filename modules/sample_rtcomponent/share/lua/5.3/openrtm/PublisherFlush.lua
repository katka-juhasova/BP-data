---------------------------------
--! @file PublisherFlush.lua
--! @brief 即座にデータ書き込みを実行するパブリッシャー定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PublisherFlush= {}
--_G["openrtm.PublisherFlush"] = PublisherFlush

local DataPortStatus = require "openrtm.DataPortStatus"
local PublisherBase = require "openrtm.PublisherBase"
local PublisherFactory = PublisherBase.PublisherFactory
local Factory = require "openrtm.Factory"

local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorDataListenerType = ConnectorListener.ConnectorDataListenerType


-- PublisherFlush初期化
-- @return PublisherFlush
PublisherFlush.new = function()
	local obj = {}
	setmetatable(obj, {__index=PublisherBase.new(info, provider)})
	local Manager = require "openrtm.Manager"
	obj._rtcout = Manager:instance():getLogbuf("PublisherFlush")
    obj._consumer  = nil
    obj._active    = false
    obj._profile   = nil
    obj._listeners = nil
    obj._retcode   = DataPortStatus.PORT_OK
    
	-- 初期化時にプロパティを設定
	-- @param prop プロパティ
	-- @return リターンコード
	function obj:init(prop)
		self._rtcout:RTC_TRACE("init()")
		return DataPortStatus.PORT_OK
	end
	-- サービスコンシューマ設定
	-- @param consumer コンシューマオブジェクト
	-- @return リターンコード
	function obj:setConsumer(consumer)
		self._rtcout:RTC_TRACE("setConsumer()")
		if consumer == nil then
			return DataPortStatus.INVALID_ARGS
		end

		self._consumer = consumer

		return DataPortStatus.PORT_OK
	end
	-- バッファ設定
	-- @param buffer バッファ
	-- @return リターンコード
	function obj:setBuffer(buffer)
		self._rtcout:RTC_TRACE("setBuffer()")
		return DataPortStatus.PORT_OK
	end
	-- コールバック設定
	-- @param info プロファイル
	-- @param listeners コールバック関数
	-- @return リターンコード
	function obj:setListener(info, listeners)
		self._rtcout:RTC_TRACE("setListeners()")

		if listeners == nil then
			self._rtcout:RTC_ERROR("setListeners(listeners == 0): invalid argument")
			return DataPortStatus.INVALID_ARGS
		end

		self._profile = info
		self._listeners = listeners

		return DataPortStatus.PORT_OK
	end
	-- データ書き込み
	-- @param data データ
	-- @param sec タイムアウト時間[s]
	-- @param usec タイムアウト時間[us]
	-- @return リターンコード
	function obj:write(data, sec, usec)
		self._rtcout:RTC_PARANOID("write()")
		if self._consumer == nil or self._listeners == nil then
			return DataPortStatus.PRECONDITION_NOT_MET
		end

		if self._retcode == DataPortStatus.CONNECTION_LOST then
			self._rtcout:RTC_DEBUG("write(): connection lost.")
			return self._retcode
		end

		self:onSend(data)

		self._retcode = self._consumer:put(data)

		if self._retcode == DataPortStatus.PORT_OK then
			self:onReceived(data)
			return self._retcode
		elseif self._retcode == DataPortStatus.PORT_ERROR then
			self:onReceiverError(data)
			return self._retcode
		elseif self._retcode == DataPortStatus.SEND_FULL then
			self:onReceiverFull(data)
			return self._retcode
		elseif self._retcode == DataPortStatus.SEND_TIMEOUT then
			self:onReceiverTimeout(data)
			return self._retcode
		elseif self._retcode == DataPortStatus.CONNECTION_LOST then
			self:onReceiverTimeout(data)
			return self._retcode
		elseif self._retcode == DataPortStatus.UNKNOWN_ERROR then
			self:onReceiverError(data)
			return self._retcode
		else
			self:onReceiverError(data)
			return self._retcode
		end
	end
	-- アクティブ状態化の確認
	-- @return true：アクティブ状態、false：非アクティブ状態
	function obj:isActive()
		return self._active
	end
	-- アクティブ化
	-- @return リターンコード
	function obj:activate()
		if self._active then
			return DataPortStatus.PRECONDITION_NOT_MET
		end

		self._active = true

		return DataPortStatus.PORT_OK
	end
	-- 非アクティブ化
	-- @return リターンコード
	function obj:deactivate()
		if not self._active then
			return DataPortStatus.PRECONDITION_NOT_MET
		end

		self._active = false

		return DataPortStatus.PORT_OK
	end

	-- データ送信後のコールバック実行
	-- @param data データ
	function obj:onSend(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_SEND]:notify(self._profile, data)
		end
	end

	-- データ受信後のコールバック実行
	-- @param data データ
	function obj:onReceived(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVED]:notify(self._profile, data)
		end
	end
	-- データ受信フル時のコールバック実行
	-- @param data データ
	function obj:onReceiverFull(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVER_FULL]:notify(self._profile, data)
		end
	end
	-- データ受信タイムアウト時のコールバック実行
	-- @param data データ
	function obj:onReceiverTimeout(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVER_TIMEOUT]:notify(self._profile, data)
		end
	end
	-- データ受信エラー時のコールバック実行
	-- @param data データ
	function obj:onReceiverError(data)
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connectorData_[ConnectorDataListenerType.ON_RECEIVER_ERROR]:notify(self._profile, data)
		end
	end

	return obj
end

-- PublisherFlush生成ファクトリ登録
PublisherFlush.Init = function()
	PublisherFactory:instance():addFactory("flush",
		PublisherFlush.new,
		Factory.Delete)
end


return PublisherFlush
