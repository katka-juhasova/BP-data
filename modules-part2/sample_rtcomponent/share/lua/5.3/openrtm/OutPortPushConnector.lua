---------------------------------
--! @file OutPortPushConnector.lua
--! @brief Push型通信OutPortConnector定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortPushConnector= {}
--_G["openrtm.OutPortPushConnector"] = OutPortPushConnector

--local oil = require "oil"
local OutPortConnector = require "openrtm.OutPortConnector"
local DataPortStatus = require "openrtm.DataPortStatus"
local BufferStatus = require "openrtm.BufferStatus"
local OutPortProvider = require "openrtm.OutPortProvider"
local OutPortProviderFactory = OutPortProvider.OutPortProviderFactory
local CdrBufferBase = require "openrtm.CdrBufferBase"
local CdrBufferFactory = CdrBufferBase.CdrBufferFactory
local InPortConsumer = require "openrtm.InPortConsumer"
local InPortConsumerFactory = InPortConsumer.InPortConsumerFactory
local PublisherBase = require "openrtm.PublisherBase"
local PublisherFactory = PublisherBase.PublisherFactory
local StringUtil = require "openrtm.StringUtil"

local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorListenerType = ConnectorListener.ConnectorListenerType


-- Push型通信OutPortConnectorの初期化
-- @param info プロファイル
-- 「buffer」という要素名にバッファの設定を格納
-- @param consumer コンシューマ
-- @param listeners コールバック
-- @param buffer バッファ
-- 指定しない場合はリングバッファを生成する
-- @return Push型通信OutPortConnector
OutPortPushConnector.new = function(info, consumer, listeners, buffer)
	--print(consumer, listeners, buffer)
	local obj = {}
	setmetatable(obj, {__index=OutPortConnector.new(info)})

	-- データ書き込み
	-- @param data data._dataを書き込み
	-- @return リターンコード(パブリッシャのデータ書き込み結果による)
	function obj:write(data)
		self._rtcout:RTC_TRACE("write()")

		local Manager = require "openrtm.Manager"

		local cdr_data = Manager:instance():cdrMarshal(data._data, data._type)
		--print(#cdr_data)

		return self._publisher:write(cdr_data, 0, 0)
	end

	-- コネクタ切断
	-- @return リターンコード
	function obj:disconnect()
		self._rtcout:RTC_TRACE("disconnect()")
		self:onDisconnect()

		if self._publisher ~= nil then
			self._rtcout:RTC_DEBUG("delete publisher")
			local pfactory = PublisherFactory:instance()
			pfactory:deleteObject(self._publisher)
		end

		self._publisher = nil


		if self._consumer ~= nil then
			self._rtcout:RTC_DEBUG("delete consumer")
			local cfactory = InPortConsumerFactory:instance()
			cfactory:deleteObject(self._consumer)
		end

		self._consumer = nil


		if self._buffer ~= nil then
			self._rtcout:RTC_DEBUG("delete buffer")
			local bfactory = CdrBufferFactory:instance()
			bfactory:deleteObject(self._buffer)
		end

		self._buffer = nil
		self._rtcout:RTC_TRACE("disconnect() done")

		return DataPortStatus.PORT_OK
	end
	-- アクティブ化
	function obj:activate()
		self._publisher:activate()
	end
	-- 非アクティブ化
	function obj:deactivate()
		self._publisher:activate()
	end
	-- バッファ取得
	-- @return バッファ
	function obj:getBuffer()
		return self._buffer
	end

	-- パブリッシャー生成
	-- @param profile コネクタプロファイル
	-- @return パブリッシャー
	function obj:createPublisher(info)
		local pub_type = info.properties:getProperty("subscription_type","flush")
		pub_type = StringUtil.normalize(pub_type)
		return PublisherFactory:instance():createObject(pub_type)
	end

	-- バッファ作成
	-- @param profile コネクタプロファイル
	-- @return バッファ
	function obj:createBuffer(info)
		local buf_type = info.properties:getProperty("buffer_type",
											   "ring_buffer")

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
	
	-- InPortサーバントオブジェクト設定
	-- @param directInPort InPortサーバントオブジェクト
	-- @return true：設定成功、false：設定失敗
	function obj:setInPort(directInPort)
		return false
	end

	obj._buffer = buffer
    obj._consumer = consumer
    obj._listeners = listeners

    obj._directInPort = nil
    obj._inPortListeners = nil

	obj._publisher = obj:createPublisher(info)
    if obj._buffer == nil then
		obj._buffer = obj:createBuffer(info)
	end


    if obj._publisher == nil or obj._buffer == nil or obj._consumer == nil then
		error("")
	end

    if obj._publisher:init(info.properties) ~= DataPortStatus.PORT_OK then
		error("")
	end



    obj._buffer:init(info.properties:getNode("buffer"))
    obj._consumer:init(info.properties)
    obj._publisher:setConsumer(obj._consumer)
    obj._publisher:setBuffer(obj._buffer)
    obj._publisher:setListener(obj._profile, obj._listeners)

    obj:onConnect()

	return obj
end


return OutPortPushConnector
