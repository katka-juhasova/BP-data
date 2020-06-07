---------------------------------
--! @file OutPortBase.lua
--! @brief アウトポート基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortBase= {}
--_G["openrtm.OutPortBase"] = OutPortBase

local oil = require "oil"

local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"
local Properties = require "openrtm.Properties"
local ConnectorListener = require "openrtm.ConnectorListener"
local ConnectorListeners = ConnectorListener.ConnectorListeners
local PublisherBase = require "openrtm.PublisherBase"
local PublisherFactory = PublisherBase.PublisherFactory
local PortBase = require "openrtm.PortBase"
local StringUtil = require "openrtm.StringUtil"


local ConnectorDataListenerType = ConnectorListener.ConnectorDataListenerType
local ConnectorListenerType = ConnectorListener.ConnectorListenerType
local ConnectorDataListener = ConnectorListener.ConnectorDataListener
local ConnectorListener = ConnectorListener.ConnectorListener


local InPortConsumer = require "openrtm.InPortConsumer"
local InPortConsumerFactory = InPortConsumer.InPortConsumerFactory
local OutPortProvider = require "openrtm.OutPortProvider"
local OutPortProviderFactory = OutPortProvider.OutPortProviderFactory

local NVUtil = require "openrtm.NVUtil"

local ConnectorBase = require "openrtm.ConnectorBase"
local ConnectorInfo = ConnectorBase.ConnectorInfo

local OutPortPushConnector = require "openrtm.OutPortPushConnector"
local OutPortPullConnector = require "openrtm.OutPortPullConnector"

-- アウトポート基底オブジェクト初期化
-- @param name ポート名
-- @param data_type データ型
-- @return アウトポート
OutPortBase.new = function(name, data_type)
	local obj = {}
	setmetatable(obj, {__index=PortBase.new(name)})
	local Manager = require "openrtm.Manager"
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue

	obj._rtcout = Manager:instance():getLogbuf(name)
	obj._rtcout:RTC_DEBUG("Port name: "..name)

	--local svr = Manager:instance():getORB():newservant(obj, nil, "IDL:omg.org/RTC/PortService:1.0")
	--local str = Manager:instance():getORB():tostring(svr)
	--obj._objref = Manager:instance():getORB():newproxy(str,"IDL:omg.org/RTC/PortService:1.0")
	--obj._profile.port_ref = obj._objref



    obj._rtcout:RTC_DEBUG("setting port.port_type: DataOutPort")
    obj:addProperty("port.port_type", "DataOutPort")

	local _data_type = string.sub(data_type, 3)
	_data_type = string.gsub(_data_type, "::", "/")
	_data_type = "IDL:".._data_type..":1.0"
    obj._rtcout:RTC_DEBUG("setting dataport.data_type: "..tostring(data_type))
    obj:addProperty("dataport.data_type", _data_type)


    local factory = PublisherFactory:instance()
    local pubs = StringUtil.flatten(factory:getIdentifiers())
	pubs = StringUtil.eraseHeadBlank(pubs)



    obj._rtcout:RTC_DEBUG("available subscription_type: "..pubs)
    obj:addProperty("dataport.subscription_type", pubs)
    obj:addProperty("dataport.io_mode", pubs)

    obj._properties    = Properties.new()
    obj._name          = name
    obj._connectors    = {}
    obj._consumers     = {}
    obj._providerTypes = ""
    obj._consumerTypes = ""
	obj._data_type = data_type


    obj._listeners = ConnectorListeners.new()

	-- 初期化時にプロパティを設定する
	-- @param prop プロパティ
	function obj:init(prop)
		self._rtcout:RTC_TRACE("init()")
		self:createRef()

		self._properties:mergeProperties(prop)


		self:configure()


		self:initConsumers()
		self:initProviders()


		local num = tonumber(self._properties:getProperty("connection_limit","-1"))
		if num == nil then
			self._rtcout:RTC_ERROR("invalid connection_limit value: "..self._properties:getProperty("connection_limit"))
		end
		self:setConnectionLimit(num)

    end
    -- 未実装
	function obj:configure()
	end
    -- 利用可能なサービスコンシューマ一覧初期化
    -- InPortConsumerFactoryからサービスコンシューマ一覧を取得する
    -- 「consumer_types」のプロパティが「all」の場合は、
    -- 利用可能なサービスコンシューマを全て利用可能にする
	function obj:initConsumers()
		self._rtcout:RTC_TRACE("initConsumers()")


		local factory = InPortConsumerFactory:instance()
		local consumer_types = factory:getIdentifiers()
		--print(StringUtil.flatten(consumer_types))
		self._rtcout:RTC_PARANOID("available InPortConsumer: "..StringUtil.flatten(consumer_types))
		local tmp_str = StringUtil.normalize(self._properties:getProperty("consumer_types"))
		--print(self._properties:getProperty("consumer_types"))

		if self._properties:hasKey("consumer_types") and tmp_str  ~= "all" then
			self._rtcout:RTC_DEBUG("allowed consumers: "..self._properties:getProperty("consumer_types"))

			local temp_types = consumer_types
			consumer_types = {}
			local active_types = StringUtil.split(self._properties:getProperty("consumer_types"), ",")

			table.sort(temp_types)
			table.sort(active_types)

			consumer_types = temp_types

			for i, v in ipairs(active_types) do
				consumer_types[#consumer_types+1] = v
			end

		end




		if #consumer_types > 0 then
			self._rtcout:RTC_PARANOID("dataflow_type push is supported")
			self:appendProperty("dataport.dataflow_type", "push")
			for i, consumer_type in ipairs(consumer_types) do
				self:appendProperty("dataport.interface_type",consumer_type)
			end
		end



		self._consumerTypes = consumer_types
	end
	-- 利用可能なサービスプロバイダ一覧初期化
	-- OutPortProviderFactoryからサービスプロバイダ一覧を取得する
    -- 「provider_types」のプロパティが「all」の場合は、
    -- 利用可能なサービスプロバイダを全て利用可能にする
	function obj:initProviders()
		self._rtcout:RTC_TRACE("initProviders()")


		local factory = OutPortProviderFactory:instance()
		local provider_types  = factory:getIdentifiers()
		self._rtcout:RTC_PARANOID("available OutPortProviders: "..StringUtil.flatten(provider_types))
		local tmp_str = StringUtil.normalize(self._properties:getProperty("provider_types"))
		if self._properties:hasKey("provider_types") and tmp_str  ~= "all" then
			self._rtcout:RTC_DEBUG("allowed providers: "..self._properties:getProperty("allowed"))

			local temp_types = provider_types
			provider_types = {}
			local active_types = StringUtil.split(self._properties:getProperty("provider_types"), ",")

			table.sort(temp_types)
			table.sort(active_types)

			provider_types = temp_types

			for i, v in ipairs(active_types) do
				provider_types[#provider_types+1] = v
			end
		end



		if #provider_types > 0 then
			self._rtcout:RTC_PARANOID("dataflow_type pull is supported")
			self:appendProperty("dataport.dataflow_type", "pull")
			for i, provider_type in ipairs(provider_types) do
				self:appendProperty("dataport.interface_type",provider_type)
			end
		end

		self._providerTypes = provider_types
	end

	-- コネクタプロファイルからインターフェース取得
	-- push型の場合はコンシューマ生成して、コネクタを生成する
	-- @param cprof コネクタプロファイル
	-- コネクタプロファイルの以下のノードからプロパティを取得
	-- dataport
	-- dataport.outport
	-- @return リターンコード
	-- RTC_OK：正常終了
	-- BAD_PARAMETER：コンシューマ生成失敗、不正なデータフロー型
	-- RTC_ERROR：コネクタ生成失敗
	function obj:subscribeInterfaces(cprof)
		self._rtcout:RTC_TRACE("subscribeInterfaces()")



		--print(self._properties)

		local prop = Properties.new(self._properties)


		local conn_prop = Properties.new()

		NVUtil.copyToProperties(conn_prop, cprof.properties)
		--print(cprof.properties[1].value)


		prop:mergeProperties(conn_prop:getNode("dataport"))


		prop:mergeProperties(conn_prop:getNode("dataport.outport"))


		local dflow_type = StringUtil.normalize(prop:getProperty("dataflow_type"))
		local profile = ConnectorInfo.new(cprof.name,
										cprof.connector_id,
										CORBA_SeqUtil.refToVstring(cprof.ports),
										prop)

		--[[local success, exception = oil.pcall(
			function()
				print(prop)
			end)
		print(exception)]]
		--print(dflow_type)
		--print(prop)
		--print(dflow_type)
		--print(prop)
		if dflow_type == "push" then
			self._rtcout:RTC_PARANOID("dataflow_type = push .... create PushConnector")

			consumer = self:createConsumer(cprof, prop)

			--print(consumer)
			if consumer == nil then
				return self._ReturnCode_t.BAD_PARAMETER
			end


			local connector = self:createConnector(cprof, prop, {consumer_ = consumer})
			--print(connector)



			if connector == nil then
				return self._ReturnCode_t.RTC_ERROR
			end

			local ret = connector:setConnectorInfo(profile)
			if ret == self._ReturnCode_t.RTC_OK then
				self._rtcout:RTC_DEBUG("subscribeInterfaces() successfully finished.")
			end


			return self._ReturnCode_t.RTC_OK
		elseif dflow_type == "pull" then
			local conn = self:getConnectorById(cprof.connector_id)
			if conn == nil then
				self._rtcout:RTC_ERROR("specified connector not found: "..cprof.connector_id)
				return self._ReturnCode_t.RTC_ERROR
			end

			local ret = conn:setConnectorInfo(profile)

			if ret == self._ReturnCode_t.RTC_OK then
				self._rtcout:RTC_DEBUG("subscribeInterfaces() successfully finished.")
			end

			return ret
		end

		self._rtcout:RTC_ERROR("unsupported dataflow_type")

		return self._ReturnCode_t.BAD_PARAMETER
	end

	-- プロバイダの初期化してインターフェースをコネクタプロファイルに登録
	-- pull型の場合はプロバイダを生成して、コネクタを生成する
	-- @param cprof コネクタプロファイル
	-- コネクタプロファイルの以下のノードからプロパティを取得
	-- dataport
	-- dataport.outport
	-- @return リターンコード
	-- RTC_OK：正常終了
	-- BAD_PARAMETER：プロバイダの初期化失敗、不正なデータフロー型
	-- RTC_ERROR：コネクタ生成失敗
	function obj:publishInterfaces(cprof)
		self._rtcout:RTC_TRACE("publishInterfaces()")


		local retval = self:_publishInterfaces()
		if retval ~= self._ReturnCode_t.RTC_OK then
			return retval
		end


		local prop = Properties.new(self._properties)

		local conn_prop = Properties.new()

		NVUtil.copyToProperties(conn_prop, cprof.properties)
		prop:mergeProperties(conn_prop:getNode("dataport"))

		prop:mergeProperties(conn_prop:getNode("dataport.outport"))



		local dflow_type = StringUtil.normalize(prop:getProperty("dataflow_type"))

		if dflow_type == "push" then
			self._rtcout:RTC_PARANOID("dataflow_type = push .... do nothing")
			return self._ReturnCode_t.RTC_OK

		elseif dflow_type == "pull" then
			self._rtcout:RTC_PARANOID("dataflow_type = pull .... create PullConnector")

			provider = self:createProvider(cprof, prop)
			if provider == nil then
				return self._ReturnCode_t.BAD_PARAMETER
			end


			local connector = self:createConnector(cprof, prop, {provider_ = provider})
			if connector == nil then
				return self._ReturnCode_t.RTC_ERROR
			end


			provider:setConnector(connector)

			self._rtcout:RTC_DEBUG("publishInterface() successfully finished.")
			return self._ReturnCode_t.RTC_OK
		end

		self._rtcout:RTC_ERROR("unsupported dataflow_type")

		return self._ReturnCode_t.BAD_PARAMETER
	end

	-- コネクタ生成
	-- @param cprof コネクタプロファイル
	-- @param prop プロパティ
	-- @param args args.provider_：プロバイダ、args.consumer_：コンシューマ
	-- @return コネクタオブジェクト
	function obj:createConnector(cprof, prop, args)
		local provider_ = args.provider_
		local consumer_ = args.consumer_
		local profile = ConnectorInfo.new(cprof.name,
									cprof.connector_id,
									CORBA_SeqUtil.refToVstring(cprof.ports),
									prop)
		local connector = nil

		local ret = nil
		local success, exception = oil.pcall(
			function()
				if consumer_ ~= nil then
					connector = OutPortPushConnector.new(profile, consumer_,
														self._listeners)

				elseif provider_  ~= nil then
					connector = OutPortPullConnector.new(profile, provider_,
														self._listeners)

				else
					self._rtcout:RTC_ERROR("provider or consumer is not passed. returned 0;")
					ret = nil
					return
				end




				if consumer_ ~= nil then
					self._rtcout:RTC_TRACE("OutPortPushConnector created")
				elseif provider_ ~= nil then
					self._rtcout:RTC_TRACE("OutPortPullConnector created")
				end


				table.insert(self._connectors, connector)
				self._rtcout:RTC_PARANOID("connector push backed: "..#self._connectors)
				ret = connector
				return
			end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR("OutPortPushConnector creation failed")
			self._rtcout:RTC_ERROR(exception)
			return nil
		end
		return ret
	end

	-- サービスプロバイダ作成
	-- 「interface_type」の要素にインターフェース型を指定
	-- 「provider」のノードにプロバイダのプロパティを指定
	-- @param cprof コネクタプロファイル
	-- @param prop プロパティ
	-- @return プロバイダ
	function obj:createProvider(cprof, prop)

		if prop:getProperty("interface_type") == "" or
			  not StringUtil.includes(self._providerTypes, prop:getProperty("interface_type")) then
			self._rtcout:RTC_ERROR("no provider found")
			self._rtcout:RTC_DEBUG("interface_type:  "..prop:getProperty("interface_type"))
			self._rtcout:RTC_DEBUG("interface_types: "..
								 StringUtil.flatten(self._providerTypes))
			return nil
		end

		self._rtcout:RTC_DEBUG("interface_type: "..prop:getProperty("interface_type"))
		local provider = OutPortProviderFactory:instance():createObject(prop:getProperty("interface_type"))

		if provider ~= nil then
			self._rtcout:RTC_DEBUG("provider created")
			provider:init(prop:getNode("provider"))

			if not provider:publishInterface(cprof.properties) then
				self._rtcout:RTC_ERROR("publishing interface information error")
				OutPortProviderFactory:instance():deleteObject(provider)
				return nil
			end

			return provider
		end

		self._rtcout:RTC_ERROR("provider creation failed")
		return nil
	end
	
	-- サービスコンシューマ作成
	-- 「interface_type」の要素にインターフェース型を指定
	-- 「consumer」のノードにコンシューマのプロパティを指定
	-- @param cprof コネクタプロファイル
	-- @param prop プロパティ
	-- @return コンシューマ
	function obj:createConsumer(cprof, prop)
		--print(prop:getProperty("interface_type"))
		--print(StringUtil.includes(self._consumerTypes, prop:getProperty("interface_type")))
		if prop:getProperty("interface_type") == "" or
			not StringUtil.includes(self._consumerTypes, prop:getProperty("interface_type")) then
			self._rtcout:RTC_ERROR("no consumer  found")
			self._rtcout:RTC_DEBUG("interface_type:  "..prop:getProperty("interface_type"))
			self._rtcout:RTC_DEBUG("interface_types: "..StringUtil.flatten(self._consumerTypes))
			return nil
		end


		self._rtcout:RTC_DEBUG("interface_type: "..prop:getProperty("interface_type"))
		local consumer = InPortConsumerFactory:instance():createObject(prop:getProperty("interface_type"))


		if consumer ~= nil then
			self._rtcout:RTC_DEBUG("consumer  created")
			consumer:init(prop:getNode("consumer"))

			if not consumer:subscribeInterface(cprof.properties) then
				self._rtcout:RTC_ERROR("interface subscription failed.")
				InPortConsumerFactory:instance():deleteObject(provider)
				return nil
			end
			return consumer
		end

		self._rtcout:RTC_ERROR("provider creation failed")
		return nil
	end

	-- IDからコネクタを取得
	-- @param id 識別子
	-- @return コネクタ
	function obj:getConnectorById(id)
		self._rtcout:RTC_TRACE("getConnectorById(id = "..id..")")

		for i, con in pairs(self._connectors) do
			if id == con:id() then
				return con
			end
		end

		self._rtcout:RTC_WARN("ConnectorProfile with the id("..id..") not found.")
		return nil
	end

	-- 指定コネクタプロファイルのコネクタを削除
	-- @param connector_profile コネクタプロファイル
	function obj:unsubscribeInterfaces(connector_profile)
	    self._rtcout:RTC_TRACE("unsubscribeInterfaces()")

		local id = connector_profile.connector_id
		self._rtcout:RTC_PARANOID("connector_id: "..id)

		for i, con in pairs(self._connectors) do
			if id == con:id() then
				con:deactivate()
				con:disconnect()
				self._connectors[i] = nil
				self._rtcout:RTC_TRACE("delete connector: "..id)
				return
			end
		end


		self._rtcout:RTC_ERROR("specified connector not found: "..id)
	end

	-- インターフェースのアクティブ化
	function obj:activateInterfaces()
		self._rtcout:RTC_TRACE("activateInterfaces()")
		for i, con in pairs(self._connectors) do
			con:activate()
			self._rtcout:RTC_DEBUG("activate connector: "..
								con:name().." "..con:id())
		end
	end

	-- インターフェースの非アクティブ化
	function obj:deactivateInterfaces()
		self._rtcout:RTC_TRACE("deactivateInterfaces()")
		for i, con in pairs(self._connectors) do
			con:deactivate()
			self._rtcout:RTC_DEBUG("deactivate connector: "..
								con:name().." "..con:id())
		end
	end


	function obj:addConnectorDataListener(listener_type, listener, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		self._rtcout:RTC_TRACE("addConnectorDataListener()")

		   if listener_type < ConnectorDataListenerType.CONNECTOR_DATA_LISTENER_NUM then
			self._rtcout:RTC_TRACE("addConnectorDataListener(%s)", ConnectorDataListener.toString(listener_type))
      		self._listeners.connectorData_[listener_type]:addListener(listener, autoclean)
			return
		end

	    self._rtcout:RTC_ERROR("addConnectorDataListener(): Unknown Listener Type")

	end

	function obj:removeConnectorDataListener(listener_type, listener)
    	self._rtcout:RTC_TRACE("removeConnectorDataListener()")

		if listener_type < ConnectorDataListenerType.CONNECTOR_DATA_LISTENER_NUM then
			self._rtcout:RTC_TRACE("removeConnectorDataListener(%s)", ConnectorDataListener.toString(listener_type))
    		self._listeners.connectorData_[listener_type]:removeListener(listener)
			return
		end

    	self._rtcout:RTC_ERROR("removeConnectorDataListener(): Unknown Listener Type")
	end
	

	function obj:addConnectorListener(listener_type, listener, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		self._rtcout:RTC_TRACE("addConnectorListener()")

		   if listener_type < ConnectorListenerType.CONNECTOR_LISTENER_NUM then
			self._rtcout:RTC_TRACE("addConnectorListener(%s)", ConnectorListener.toString(listener_type))
      		self._listeners.connector_[listener_type]:addListener(listener, autoclean)
			return
		end

	    self._rtcout:RTC_ERROR("addConnectorListener(): Unknown Listener Type")

	end

	function obj:removeConnectorListener(listener_type, listener)
    	self._rtcout:RTC_TRACE("removeConnectorListener()")

		if listener_type < ConnectorListenerType.CONNECTOR_LISTENER_NUM then
			self._rtcout:RTC_TRACE("removeConnectorListener(%s)", ConnectorListener.toString(listener_type))
    		self._listeners.connector_[listener_type]:removeListener(listener)
			return
		end

    	self._rtcout:RTC_ERROR("removeConnectorListener(): Unknown Listener Type")
	end
	

	return obj
end


return OutPortBase
