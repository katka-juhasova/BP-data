---------------------------------
--! @file PortBase.lua
--! @brief ポート基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PortBase= {}
--_G["openrtm.PortBase"] = PortBase

local oil = require "oil"
local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"
local Properties = require "openrtm.Properties"
local NVUtil = require "openrtm.NVUtil"
local StringUtil = require "openrtm.StringUtil"
local PortConnectListener = require "openrtm.PortConnectListener"
local PortConnectListenerType = PortConnectListener.PortConnectListenerType
local PortConnectRetListenerType = PortConnectListener.PortConnectRetListenerType

local uuid = require "uuid"

local RTCUtil = require "openrtm.RTCUtil"



local find_conn_id = {}
-- コネクタIDが一致しているか判定する関数オブジェクト初期化
-- @param id_ コネクタID
-- @return 関数オブジェクト
find_conn_id.new = function(id_)
	local obj = {}
	obj._id = id_
	-- コネクタIDが一致しているか判定する
	-- @param self 自身のオブジェクト
	-- @param cprof コネクタプロファイル
	-- @return true：一致、false：不一致
	local call_func = function(self, cprof)
		return (self._id == cprof.connector_id)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



local find_port_ref = {}
-- ポートのオブジェクトリファレンスが一致するかを判定する関数オブジェクト
-- @param port_ref ポート
-- @return 関数オブジェクト
find_port_ref.new = function(port_ref)
	local obj = {}
	obj._port_ref = port_ref
	-- ポートのオブジェクトリファレンスが一致するかを判定する
	-- @param self 自身のオブジェクト
	-- @param port_ref ポート
	-- @return true：一致、false：不一致
	local call_func = function(self, port_ref)
		--print(self._port_ref, port_ref, self._port_ref._is_equivalent, port_ref._is_equivalent)
		return NVUtil._is_equivalent(self._port_ref, port_ref, self._port_ref.getPortRef, port_ref.getPortRef)
		--[[local ret = false
		local success, exception = oil.pcall(
			function()
			ret = (self._port_ref:get_port_profile().name == port_ref:get_port_profile().name)
			end)
		return ret]]
		--return self._port_ref:_is_equivalent(port_ref)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


local find_interface = {}

-- インターフェースが一致しているか判定する関数オブジェクト
-- @param name インターフェース名
-- @param pol インターフェースの方向(PROVIDED、REQUIRED)
-- @return 関数オブジェクト
find_interface.new = function(name, pol)
	local obj = {}
	obj._name = name
	obj._pol = pol
	-- インターフェースが一致しているか判定する
	-- @param self 自身のオブジェクト
	-- @param prof インターフェースのプロファイル
	-- @return true：一致、false：不一致
	local call_func = function(self, prof)
		local name = prof.instance_name
		return ((self._name == name) and (self._pol == prof.polarity))
	end
	setmetatable(obj, {__call=call_func})
	return obj

end


-- ポート基底オブジェクト初期化
-- @param name ポート名
-- @return ポート
PortBase.new = function(name)
	local obj = {}

	local Manager = require "openrtm.Manager"
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue

	obj._ownerInstanceName = "unknown"
	--print("test3:",obj, obj._objref)


    obj._profile = {name="", interfaces={}, port_ref=oil.corba.idl.null, connector_profiles={}, owner=oil.corba.idl.null, properties={}}


    if name == nil then
		obj._profile.name = "unknown.unknown"
    else
		obj._profile.name = obj._ownerInstanceName.."."..name
	end


    obj._profile.owner = oil.corba.idl.null


    obj._rtcout = Manager:instance():getLogbuf(name)
    obj._onPublishInterfaces = nil
    obj._onSubscribeInterfaces = nil
    obj._onConnected = nil
    obj._onUnsubscribeInterfaces = nil
    obj._onDisconnected = nil
    obj._onConnectionLost = nil
    obj._connectionLimit   = -1
    obj._portconnListeners = nil
	obj._properties = Properties.new()
	obj._svr = nil
	obj._connectors = {}

	-- ポートプロファイル取得
	-- @return プロファイル
	function obj:get_port_profile()
		self._rtcout:RTC_TRACE("get_port_profile()")

		self:updateConnectors()
		local connectors = {}
		for i,con in ipairs(self._profile.connector_profiles) do
			local conn_prof = {name=con.name,
							connector_id=con.connector_id,
							ports=con.ports,
							properties={}}
			for j,conf in ipairs(con.properties) do
				con.properties[j] = {name=conf.name, value=NVUtil.any_from_any(conf.value)}
			end
			table.insert(connectors, conn_prof)
		end


		local prof = {name=self._profile.name,
				interfaces=self._profile.interfaces,
				port_ref=self._profile.port_ref,
				--port_ref="test",
				connector_profiles=connectors,
				owner=self._profile.owner,
				properties=self._profile.properties}
		return prof
	end

	-- ポートプロファイル取得
	-- @return プロファイル
	function obj:getPortProfile()
		self._rtcout:RTC_TRACE("getPortProfile()")
		return self._profile
	end

	-- コネクタプロファイル一覧取得
	-- @return プロファイル一覧
	function obj:get_connector_profiles()
		self._rtcout:RTC_TRACE("get_connector_profiles()")

		self:updateConnectors()

		return self._profile.connector_profiles
	end

	-- コネクタプロファイル取得
	-- @param connector_id コネクタID
	-- @return プロファイル
	function obj:get_connector_profile(connector_id)
		self._rtcout:RTC_TRACE("get_connector_profile("..connector_id..")")

		self:updateConnectors()

		local index = CORBA_SeqUtil.find(self._profile.connector_profiles,
												find_conn_id.new(connector_id))
		if index < 0 then
		  local conn_prof = {name="", connector_id="", ports={}, properties={}}
		  return conn_prof
		end

		local conn_prof = {name=self._profile.connector_profiles[index].name,
					connector_id=self._profile.connector_profiles[index].connector_id,
					ports=self._profile.connector_profiles[index].ports,
					properties=self._profile.connector_profiles[index].properties}
		return conn_prof
	end

	-- コネクタ接続
	-- @param connector_profile コネクタプロファイル
	-- @return リターンコード、コネクタプロファイル
	function obj:connect(connector_profile)
		self._rtcout:RTC_TRACE("connect()")
		if self:isEmptyId(connector_profile) then
			self:setUUID(connector_profile)
		else
			--print(self:isExistingConnId(connector_profile.connector_id))
			if self:isExistingConnId(connector_profile.connector_id) then
				self._rtcout:RTC_ERROR("Connection already exists.")
				return self._ReturnCode_t.PRECONDITION_NOT_MET, connector_profile
			end
		end


		local retval = self._ReturnCode_t.BAD_PARAMETER
		local success, exception = oil.pcall(
			function()
				--print(#connector_profile.ports)
				retval,connector_profile = connector_profile.ports[1]:notify_connect(connector_profile)
				--print(retval)
				retval = NVUtil.getReturnCode(retval)
				if retval ~= self._ReturnCode_t.RTC_OK then
					self._rtcout:RTC_ERROR("Connection failed. cleanup.")
					self:disconnect(connector_profile.connector_id)
				end
			end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR(exception)
			return self._ReturnCode_t.BAD_PARAMETER, connector_profile
		end
		--print(retval)
		--local conn_prof = {name="",
		--					connector_id="",
		--					ports={},
		--					properties={}}
		return retval, connector_profile
	end

	-- コネクタ切断
	-- @param connector_id コネクタID
	-- @return リターンコード
	function obj:disconnect(connector_id)
		self._rtcout:RTC_TRACE("disconnect("..connector_id..")")

		local index = self:findConnProfileIndex(connector_id)

		if index < 0 then
			self._rtcout:RTC_ERROR("Invalid connector id: "..connector_id)
			return self._ReturnCode_t.BAD_PARAMETER
		end

		local prof = self._profile.connector_profiles[index]



		if #prof.ports < 1 then
			self._rtcout:RTC_FATAL("ConnectorProfile has empty port list.")
			return self._ReturnCode_t.PRECONDITION_NOT_MET
		end
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				ret = prof.ports[1]:notify_disconnect(connector_id)
			end)
		if not success then
			self._rtcout:RTC_WARN(exception)
		end


		if ret ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("notify_disconnect() for all ports failed.")
			return self._ReturnCode_t.RTC_ERROR
		else
			return ret
		end
	end

	-- コネクタ切断実行関数
	-- @param connector_id コネクタID
	-- @return リターンコード
	function obj:notify_disconnect(connector_id)
		self._rtcout:RTC_TRACE("notify_disconnect("..connector_id..")")

		local index = self:findConnProfileIndex(connector_id)

		if index < 0 then
			self._rtcout:RTC_ERROR("Invalid connector id: "..connector_id)
			return self._rtcout.BAD_PARAMETER
		end

		local prof = {name = self._profile.connector_profiles[index].name,
				connector_id = self._profile.connector_profiles[index].connector_id,
				ports = self._profile.connector_profiles[index].ports,
				properties = self._profile.connector_profiles[index].properties}

		self:onNotifyDisconnect(self:getName(), prof)

		local retval = self:disconnectNext(prof)
		self:onDisconnectNextport(self:getName(), prof, retval)

		if self._onUnsubscribeInterfaces ~= nil then
			self._onUnsubscribeInterfaces(prof)
		end
		self:onUnsubscribeInterfaces(self:getName(), prof)
		self:unsubscribeInterfaces(prof)

		if self._onDisconnected ~= nil then
			self._onDisconnected(prof)
		end

		table.remove(self._profile.connector_profiles, index)

		self:onDisconnected(self:getName(), prof, retval)
		return retval
	end

	-- コネクタ接続実行関数
	-- @param connector_profile コネクタプロファイル
	-- @return リターンコード、コネクタプロファイル
	function obj:notify_connect(connector_profile)

		self._rtcout:RTC_TRACE("notify_connect()")



		local prop = Properties.new()
		NVUtil.copyToProperties(prop, connector_profile.properties)


		local default_value = StringUtil.toBool(self._properties:getProperty("allow_dup_connection"), "YES","NO",false)

		if not StringUtil.toBool(prop:getProperty("dataport.allow_dup_connection"), "YES","NO",default_value) then
		end


		local retval = {}

		self:onNotifyConnect(self:getName(),connector_profile)


		retval[1] = self:publishInterfaces(connector_profile)
		--for i, v in ipairs(connector_profile.properties) do
		--	print(v.name, v.value)
		--end

		if retval[1] ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("publishInterfaces() in notify_connect() failed.")
		end

		self:onPublishInterfaces(self:getName(), connector_profile, retval[1])
		if self._onPublishInterfaces ~= nil then
			self._onPublishInterfaces(connector_profile)
		end


		retval[2], connector_profile = self:connectNext(connector_profile)
		retval[2] = NVUtil.getReturnCode(retval[2])
		--print("test2", retval[2])
		if retval[2] ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("connectNext() in notify_connect() failed.")
		end


		self:onConnectNextport(self:getName(), connector_profile, retval[2])

		if self._onSubscribeInterfaces ~= nil then
			self._onSubscribeInterfaces(connector_profile)
		end

		retval[3] = self:subscribeInterfaces(connector_profile)
		if retval[3] ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("subscribeInterfaces() in notify_connect() failed.")
		end


		self:onSubscribeInterfaces(self:getName(), connector_profile, retval[3])

		self._rtcout:RTC_PARANOID(#self._profile.connector_profiles.." connectors are existing")


		local index = self:findConnProfileIndex(connector_profile.connector_id)

		--print(index)
		if index < 0 then
			table.insert(self._profile.connector_profiles, connector_profile)
			--print(#self._profile.connector_profiles)
			self._rtcout:RTC_PARANOID("New connector_id. Push backed.")

		else
			self._profile.connector_profiles[index] = connector_profile
			self._rtcout:RTC_PARANOID("Existing connector_id. Updated.")
		end



		for i, ret in ipairs(retval) do
			--print(i,ret)
			if ret ~= self._ReturnCode_t.RTC_OK then
				self:onConnected(self:getName(), connector_profile, ret)
				return ret, connector_profile
			end
		end



		if self._onConnected ~= nil then
			self._onConnected(connector_profile)
		end
		self:onConnected(self:getName(), connector_profile, self._ReturnCode_t.RTC_OK)

		local conn_prof = {name=connector_profile.name,
							connector_id=connector_profile.connector_id,
							ports=connector_profile.ports,
							properties={}}

		for i,v in ipairs(connector_profile.properties) do
			conn_prof.properties[i] = {name=v.name, value=NVUtil.any_from_any(v.value)}
			--print(v.name, v.value)
			--print(conn_prof.properties[i].name, conn_prof.properties[i].value)
		end


		return self._ReturnCode_t.RTC_OK, conn_prof
	end

	-- コネクタ一覧更新
	function obj:updateConnectors()

		local connector_ids = {}
		local clist = self._profile.connector_profiles

		for i, cprof in ipairs(clist) do
			if not self:checkPorts(cprof.ports) then
				table.insert(connector_ids, cprof.connector_id)
				self._rtcout:RTC_WARN("Dead connection: "..cprof.connector_id)
			end
		end

		for i, cid in ipairs(connector_ids) do
			self:disconnect(cid)
		end

    end

	-- コネクタ一覧取得
	-- @return コネクタ一覧
	function obj:connectors()
		self._rtcout:RTC_TRACE("connectors(): size = "..#self._connectors)
		return self._connectors
	end

	-- ポートが生存しているかを確認
	-- @param ports ポート
	-- @return true：生存、false：消滅済み
 	function obj:checkPorts(ports)
		local ret = true
		for i, port in ipairs(ports) do
			--print(NVUtil._non_existent(port))
			if NVUtil._non_existent(port) then
				self._rtcout:RTC_WARN("Dead Port reference detected.")
				ret = false
			end
		end

		return ret
	end

	-- IDが空かを判定
	-- @param コネクタプロファイル
	-- @return true：空
 	function obj:isEmptyId(connector_profile)
		return (connector_profile.connector_id == "")
	end

	-- コネクタIDがすでに登録済みかを確認
	-- @param id_ コネクタID
	-- @return true：登録済み、false：未登録
 	function obj:isExistingConnId(id_)
		return (CORBA_SeqUtil.find(self._profile.connector_profiles,
                                           find_conn_id.new(id_)) >= 0)
	end

	-- コネクタ接続実行時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	function obj:onNotifyConnect(portname, profile)
		if self._portconnListeners ~= nil then
			local _type = PortConnectListenerType.ON_NOTIFY_CONNECT
			self._portconnListeners.portconnect_[_type]:notify(portname, profile)
		end
    end
    -- コネクタ切断実行時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	function obj:onNotifyDisconnect(portname, profile)
		if self._portconnListeners ~= nil then
			local _type = PortConnectListenerType.ON_NOTIFY_DISCONNECT
			self._portconnListeners.portconnect_[_type]:notify(portname, profile)
		end
    end
    -- インターフェス解放時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	function obj:onUnsubscribeInterfaces(portname, profile)
		if self._portconnListeners ~= nil then
			local _type = PortConnectListenerType.ON_UNSUBSCRIBE_INTERFACES
			self._portconnListeners.portconnect_[_type]:notify(portname, profile)
		end
    end
    -- インターフェス登録時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	-- @param ret リターンコード
	function obj:onPublishInterfaces(portname, profile, ret)
		if self._portconnListeners ~= nil then
			local _type = PortConnectRetListenerType.ON_PUBLISH_INTERFACES
			self._portconnListeners.portconnret_[_type]:notify(portname, profile, ret)
		end
    end
    -- 次のポート接続時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	-- @param ret リターンコード
	function obj:onConnectNextport(portname, profile, ret)
		if self._portconnListeners ~= nil then
			local _type = PortConnectRetListenerType.ON_CONNECT_NEXTPORT
			self._portconnListeners.portconnret_[_type]:notify(portname, profile, ret)
		end
    end
    -- インターフェ－ス取得時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	-- @param ret リターンコード
	function obj:onSubscribeInterfaces(portname, profile, ret)
		if self._portconnListeners ~= nil then
			local _type = PortConnectRetListenerType.ON_SUBSCRIBE_INTERFACES
			self._portconnListeners.portconnret_[_type]:notify(portname, profile, ret)
		end
    end
    -- コネクタ接続後のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	-- @param ret リターンコード
	function obj:onConnected(portname, profile, ret)
		if self._portconnListeners ~= nil then
			local _type = PortConnectRetListenerType.ON_CONNECTED
			self._portconnListeners.portconnret_[_type]:notify(portname, profile, ret)
		end
    end
    -- 次のポート切断時のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	-- @param ret リターンコード
	function obj:onDisconnectNextport(portname, profile, ret)
		if self._portconnListeners ~= nil then
			local _type = PortConnectRetListenerType.ON_DISCONNECT_NEXT
			self._portconnListeners.portconnret_[_type]:notify(portname, profile, ret)
		end
    end
    -- コネクタ接断後のコールバック実行
	-- @param portname ポート名
	-- @param profile ポートプロファイル
	-- @param ret リターンコード
	function obj:onDisconnected(portname, profile, ret)
		if self._portconnListeners ~= nil then
			local _type = PortConnectRetListenerType.ON_DISCONNECTED
			self._portconnListeners.portconnret_[_type]:notify(portname, profile, ret)
		end
    end

	-- ポート名取得
	-- @return ポート名
	function obj:getName()
		self._rtcout:RTC_TRACE("getName() = "..self._profile.name)
		return self._profile.name
	end

	-- インターフェースをコネクタプロファイルに登録
	-- @param connector_profile コネクタプロファイル
	-- @return リターンコード
	function obj:publishInterfaces(connector_profile)
		--print("publishInterfaces")
		return self._ReturnCode_t.BAD_PARAMETER
	end

	-- コネクタ接続可能かの判定
	-- @return リターンコード
	function obj:_publishInterfaces()
		if not (self._connectionLimit < 0) then
			if self._connectionLimit <= #self._profile.connector_profiles then
				self._rtcout:RTC_PARANOID("Connected number has reached the limitation.")
				self._rtcout:RTC_PARANOID("Can connect the port up to "..self._connectionLimit.." ports.")
				self._rtcout:RTC_PARANOID(#self._profile.connector_profiles.." connectors are existing")
				return self._ReturnCode_t.RTC_ERROR
			end
		end

		return self._ReturnCode_t.RTC_OK
	end

	-- 次のポートを接続
	-- @param connector_profile コネクタプロファイル
	-- @return リターンコード、コネクタプロファイル
	function obj:connectNext(connector_profile)
		--print("test:",self,self._profile.port_ref)
		--print(connector_profile.ports[1]:get_port_profile().name)
		local index = CORBA_SeqUtil.find(connector_profile.ports,
											find_port_ref.new(self._profile.port_ref))
		--print(index)



		if index < 0 then
			return self._ReturnCode_t.BAD_PARAMETER, connector_profile
		end

		index = index + 1
		--print(index)
		local p = connector_profile.ports[index]
		--print(p)
		if p ~= nil then
			--[[for i,v in ipairs(connector_profile.properties) do
				print(v.name,v.value)
			end]]
			local prop = {}
			for i, v in ipairs(connector_profile.properties) do
				prop[i] = {name=v.name, value=NVUtil.any_from_any(v.value)}
			end
			connector_profile.properties = prop
			return p:notify_connect(connector_profile)
		end

		return self._ReturnCode_t.RTC_OK, connector_profile
	end
	-- 次のポートを切断
	-- @param connector_profile コネクタプロファイル
	-- @return リターンコード
	function obj:disconnectNext(connector_profile)

		local index = CORBA_SeqUtil.find(connector_profile.ports,
												find_port_ref.new(self._profile.port_ref))
		if index < 0 then
			return self._ReturnCode_t.BAD_PARAMETER
		end

		if index == #connector_profile.ports then
			return self._ReturnCode_t.RTC_OK
		end

		index = index + 1



		local p = connector_profile.ports[index]
		--print(p,index)
		local ret = self._ReturnCode_t.RTC_ERROR
		while p ~= nil do
			local success, exception = oil.pcall(
				function()
					index = index + 1
					ret = p:notify_disconnect(connector_profile.connector_id)
				end)

			if not success then
				self._rtcout:RTC_WARN(exception)
			end
			p = connector_profile.ports[index]

		end


		return ret
	end

	-- IDからコネクタプロファイル取得
	-- @param id_ コネクタID
	-- @return 配列の番号
	function obj:findConnProfileIndex(id_)
		return CORBA_SeqUtil.find(self._profile.connector_profiles,
                                           find_conn_id.new(id_))
	end
	-- コネクタプロファイルにUUIDを設定
	-- @param connector_profile コネクタプロファイル
	function obj:setUUID(connector_profile)
		connector_profile.connector_id = self:getUUID()
		--print(connector_profile.connector_id)
    end
    -- UUID生成
    -- @return UUID
	function obj:getUUID()
		return uuid()
	end
	-- コネクタプロファイルからインターフェース取得
	-- @param cprof コネクタプロファイル
	-- @return リターンコード
	function obj:subscribeInterfaces(connector_profile)
		return self._ReturnCode_t.BAD_PARAMETER
    end
    -- プロファイルの設定
    -- @param _key キー
    -- @param _value 値
	function obj:addProperty(_key, _value)
		table.insert(self._profile.properties, {name=_key, value=_value})
	end
    -- プロファイルの設定追加
    -- @param _key キー
    -- @param _value 値
	function obj:appendProperty(key, value)
		--print(key, value)
		NVUtil.appendStringValue(self._profile.properties, key, value)
		--print(self._profile.properties)
	end
	-- コネクタプロファイルのインターフェース設定解除
	-- @return リターンコード
	function obj:unsubscribeInterfaces(connector_profile)
		return self._ReturnCode_t.BAD_PARAMETER
	end
	-- コネクタ最大数設定
	-- @param limit_value コネクタ最大数
	function obj:setConnectionLimit(limit_value)
		self._connectionLimit = limit_value
	end

	-- インターフェース追加
	-- @param _instance_name インスタンス名
	-- @param _type_name 型名
	-- @param pol 方向
	-- @return true：追加成功、false：追加失敗
	function obj:appendInterface(_instance_name, _type_name, pol)
		local index = CORBA_SeqUtil.find(self._profile.interfaces,
									find_interface.new(_instance_name, pol))

		if index >= 0 then
			return false
		end


		local prof = {instance_name=_instance_name, type_name=_type_name, polarity=pol}
		table.insert(self._profile.interfaces, prof)

		return true
	end

	-- オーナーのRTC設定
	-- @param owner RTC
	function obj:setOwner(owner)
		local prof = owner:get_component_profile()
		self._ownerInstanceName = prof.instance_name
		self._rtcout:RTC_TRACE("setOwner("..self._ownerInstanceName..")")


		local plist = StringUtil.split(self._profile.name, "%.")
		if self._ownerInstanceName == "" then
			self._rtcout:RTC_ERROR("Owner is not set.")
			self._rtcout:RTC_ERROR("addXXXPort() should be called in onInitialize().")
		end
		local portname = self._ownerInstanceName.."."..plist[#plist]

		if owner.getObjRef == nil then
			self._profile.owner = owner
		else
			self._profile.owner = owner:getObjRef()
		end
		self._profile.name = portname
	end

	-- ポートコネクタコールバックの設定
	-- @param portconnListeners ポートコネクタコールバック関数
	function obj:setPortConnectListenerHolder(portconnListeners)
		self._portconnListeners = portconnListeners
    end

	-- オブジェクトリファレンス取得
	-- @return オブジェクトリファレンス
	function obj:getPortRef()
		self._rtcout:RTC_TRACE("getPortRef()")
		return self._profile.port_ref
	end
	function obj:getObjRef()
		return self._objref
	end

	-- プロファイル取得
	-- @return プロファイル
	function obj:getProfile()
		self._rtcout:RTC_TRACE("getProfile()")
		return self._profile
	end

	-- 全コネクタ切断
	-- @return リターンコード
	function obj:disconnect_all()
		self._rtcout:RTC_TRACE("disconnect_all()")

		local plist = self._profile.connector_profiles


		local retcode = self._ReturnCode_t.RTC_OK
		local len_ = #plist
		self._rtcout:RTC_DEBUG("disconnecting "..len_.." connections.")



		for i, con in ipairs(plist) do
			tmpret = self:disconnect(con.connector_id)
			if tmpret ~= self._ReturnCode_t.RTC_OK then
				retcode = tmpret
			end
		end


		return retcode
	end

	-- オブジェクトリファレンス設定
	-- @param port_ref オブジェクトリファレンス
	function obj:setPortRef(port_ref)
		self._rtcout:RTC_TRACE("setPortRef()")
		self._profile.port_ref = port_ref
	end

	-- オブジェクトリファレンス生成
	function obj:createRef()
		--print("createRef")
		local Manager = require "openrtm.Manager"
		self._svr = Manager:instance():getORB():newservant(self, nil, "IDL:omg.org/RTC/PortService:1.0")
		self._objref = RTCUtil.getReference(Manager:instance():getORB(), self._svr, "IDL:omg.org/RTC/PortService:1.0")
		self._profile.port_ref = self._objref
	end

	-- インターフェースの非アクティブ化
	function obj:deactivate()
		local Manager = require "openrtm.Manager"
		if self._svr ~= nil then
			Manager:instance():getORB():deactivate(self._svr)
		end
	end

	return obj
end


return PortBase
