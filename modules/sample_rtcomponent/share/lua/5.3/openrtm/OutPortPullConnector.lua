---------------------------------
--! @file OutPortPullConnector.lua
--! @brief Pull型通信OutPortConnector定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortPullConnector= {}
--_G["openrtm.OutPortPullConnector"] = OutPortPullConnector

local OutPortConnector = require "openrtm.OutPortConnector"
local DataPortStatus = require "openrtm.DataPortStatus"
local CdrBufferBase = require "openrtm.CdrBufferBase"
local CdrBufferFactory = CdrBufferBase.CdrBufferFactory
local OutPortProvider = require "openrtm.OutPortProvider"
local OutPortProviderFactory = OutPortProvider.OutPortProviderFactory

local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorListenerType = ConnectorListener.ConnectorListenerType


-- Pull型通信OutPortConnectorの初期化
-- @param info プロファイル
-- 「buffer」という要素名にバッファの設定を格納
-- @param provider プロバイダ
-- @param listeners コールバック
-- @param buffer バッファ
-- 指定しない場合はリングバッファを生成する
-- @return Pull型通信OutPortConnector
OutPortPullConnector.new = function(info, provider, listeners, buffer)
	local obj = {}
	setmetatable(obj, {__index=OutPortConnector.new(info)})
	
	-- データ書き込み
	-- @param data data._dataを書き込み
	-- @return リターンコード(バッファの書き込み結果による)
	function obj:write(data)
		local Manager = require "openrtm.Manager"

		local cdr_data = Manager:instance():cdrMarshal(data._data, data._type)
		--print(cdr_data)


		if self._buffer ~= nil then
			self._buffer:write(cdr_data)
		else
			return DataPortStatus.UNKNOWN_ERROR
		end
		return DataPortStatus.PORT_OK
	end

	-- コネクタ切断
	-- @return リターンコード
	function obj:disconnect()
		self._rtcout:RTC_TRACE("disconnect()")
		self:onDisconnect()

		if self._provider ~= nil then
			OutPortProviderFactory:instance():deleteObject(self._provider)
			self._provider:exit()
		end
		self._provider = nil


		if self._buffer ~= nil then
			CdrBufferFactory:instance():deleteObject(self._buffer)
		end
		self._buffer = nil


		return DataPortStatus.PORT_OK
	end

	-- バッファ取得
	-- @return バッファ
	function obj:getBuffer()
		return self._buffer
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
	function obj:createBuffer(info)
		local buf_type = info.properties:getProperty("buffer_type","ring_buffer")
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






	obj._provider = provider
    obj._listeners = listeners
    obj._buffer = buffer


    obj._inPortListeners = nil



    obj._value = nil

    if obj._buffer == nil then
		obj._buffer = obj:createBuffer(info)
	end

    if obj._provider == nil or obj._buffer == nil then
		obj._rtcout:RTC_ERROR("Exeption: in OutPortPullConnector.__init__().")
		error("")
	end

    obj._buffer:init(info.properties:getNode("buffer"))
    obj._provider:init(info.properties)
    obj._provider:setBuffer(obj._buffer)
    obj._provider:setConnector(obj)
    obj._provider:setListener(info, obj._listeners)
    obj:onConnect()
	return obj
end


return OutPortPullConnector
