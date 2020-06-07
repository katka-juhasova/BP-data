---------------------------------
--! @file InPortPullConnector.lua
--! @brief Pull型通信InPortConnector定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local InPortPullConnector= {}
--_G["openrtm.InPortPullConnector"] = InPortPullConnector

local InPortConnector = require "openrtm.InPortConnector"
local DataPortStatus = require "openrtm.DataPortStatus"

local CdrBufferBase = require "openrtm.CdrBufferBase"
local CdrBufferFactory = CdrBufferBase.CdrBufferFactory
local OutPortConsumer = require "openrtm.OutPortConsumer"
local OutPortConsumerFactory = OutPortConsumer.OutPortConsumerFactory

local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorListenerType = ConnectorListener.ConnectorListenerType

-- Pull型通信InPortConnectorの初期化
-- @param info プロファイル
-- 「buffer」という要素名にバッファの設定を格納
-- @param consumer コンシューマ
-- @param listeners コールバック
-- @param buffer バッファ
-- 指定しない場合はリングバッファを生成する
-- @return Pull型通信InPortConnector
InPortPullConnector.new = function(info, consumer, listeners, buffer)
	local obj = {}
	setmetatable(obj, {__index=InPortConnector.new(info, buffer)})

	-- データ読み込み
	-- @param data data._dataにデータを格納
	-- @return リターンコード
	-- PORT_OK：get関数がPORT_OKを返す
	-- PORT_ERROR：コンシューマがnil、データ型が不明
	function obj:read(data)
		self._rtcout:RTC_TRACE("InPortPullConnector.read()")
		if self._consumer == nil then
			return DataPortStatus.PORT_ERROR
		end

		--print(self._dataType)
		if self._dataType == nil then
			return DataPortStatus.PORT_ERROR
		end



		local cdr_data = {_data=""}
		local ret = self._consumer:get(cdr_data)

		if ret == DataPortStatus.PORT_OK then
			local Manager = require "openrtm.Manager"
			data._data = Manager:instance():cdrUnmarshal(cdr_data._data, self._dataType)
		end


		return ret
	end

	-- コネクタ切断
	-- @return リターンコード
	function obj:disconnect()
		self._rtcout:RTC_TRACE("disconnect()")
		self:onDisconnect()
		if self._consumer ~= nil then
			OutPortConsumerFactory:instance():deleteObject(self._consumer)
		end
		self._consumer = nil

		return DataPortStatus.PORT_OK
	end

	-- アクティブ化
	function obj:activate()
	end

	-- 非アクティブ化
	function obj:deactivate()
	end

	-- バッファ作成
	-- リングバッファを生成する
	-- @param profile コネクタプロファイル
	-- @return バッファ
	function obj:createBuffer(profile)
		local buf_type = profile.properties:getProperty("buffer_type","ring_buffer")
		return CdrBufferFactory:instance():createObject(buf_type)
	end

	-- コネクタ接続時のコールバック呼び出し
	function obj:onConnect()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_CONNECT]:notify(self._profile)
		end
	end

	-- コネクタ切断時のコールバック呼び出し
	function obj:onDisconnect()
		if self._listeners ~= nil and self._profile ~= nil then
			self._listeners.connector_[ConnectorListenerType.ON_DISCONNECT]:notify(self._profile)
		end
	end

    obj._consumer = consumer
    obj._listeners = listeners


    if buffer == nil then
		obj._buffer = obj:createBuffer(obj._profile)
	end

    if obj._buffer == nil or obj._consumer == nil then
		error("")
	end

    obj._buffer:init(info.properties:getNode("buffer"))
    obj._consumer:init(info.properties)
    obj._consumer:setBuffer(obj._buffer)
    obj._consumer:setListener(info, obj._listeners)
    obj:onConnect()
	return obj
end


return InPortPullConnector
