---------------------------------
--! @file CORBA_RTCUtil.lua
--! @brief RTC操作関数定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local CORBA_RTCUtil = {}
--_G["openrtm.CORBA_RTCUtil"] = CORBA_RTCUtil

local oil = require "oil"
local RTObject = require "openrtm.RTObject"
local NVUtil = require "openrtm.NVUtil"
local Properties = require "openrtm.Properties"
local StringUtil = require "openrtm.StringUtil"




-- コンポーネントプロファイル取得
-- @param rtc RTC
-- @return コンポーネントプロファイル(プロパティ形式)
CORBA_RTCUtil.get_component_profile = function(rtc)
	local prop = Properties.new()
	if rtc == oil.corba.idl.null then
		return prop
	end
	local prof = rtc:get_component_profile()
	NVUtil.copyToProperties(prop, prof.properties)
	return prop
end


-- RTCの存在確認
-- @param rtc RTC
-- @return true：存在する
CORBA_RTCUtil.is_existing = function(rtc)
	local ret = true
	if NVUtil._non_existent(rtc) then
		ret = false
	end
	return ret
end

-- RTCがデフォルトの実行コンテキストで生存しているかを確認
-- @param rtc RTC
-- @return true：生存
CORBA_RTCUtil.is_alive_in_default_ec = function(rtc)
	local ec = CORBA_RTCUtil.get_actual_ec(rtc)
	if ec == oil.corba.idl.null then
		return false
	end
	return rtc:is_alive(ec)
end





-- RTCから指定IDの実行コンテキストを取得
-- @param rtc RTC
-- @param ec_id
-- @return 実行コンテキスト
CORBA_RTCUtil.get_actual_ec = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if ec_id == nil then
		ec_id = 0
	end
	if ec_id < 0 then
		return oil.corba.idl.null
	end


	if rtc == oil.corba.idl.null then
		return oil.corba.idl.null
	end

	if ec_id < RTObject.ECOTHER_OFFSET then
		local eclist = rtc:get_owned_contexts()
		if ec_id >= #eclist then
			return oil.corba.idl.null
		end

		if eclist[ec_id+1] == nil then
			return oil.corba.idl.null
		end
		return eclist[ec_id+1]
	elseif ec_id >= RTObject.ECOTHER_OFFSET then
		local pec_id = ec_id - RTObject.ECOTHER_OFFSET
		local eclist = rtc:get_participating_contexts()
		--print(pec_id, #eclist)
		if pec_id >= #eclist then
			return oil.corba.idl.null
		end
		if eclist[pec_id+1] == nil then
			return oil.corba.idl.null
		end
		return eclist[pec_id+1]
	end
end


-- 対象RTCの指定実行コンテキストのIDを取得
-- @param rtc RTC
-- @param ec 実行コンテキスト
-- @return ID
-- 存在しない場合は-1
CORBA_RTCUtil.get_ec_id = function(rtc, ec)
	if rtc == oil.corba.idl.null then
		return -1
	end
	if ec == oil.corba.idl.null then
		return -1
	end

	local eclist_own = rtc:get_owned_contexts()

	local count = 0
	for k,e in ipairs(eclist_own) do
		if e ~= oil.corba.idl.null then
			if NVUtil._is_equivalent(e, ec, e.getObjRef, ec.getObjRef) then
				return count
			end
		end
		count = count+1
	end
	local eclist_pec = rtc:get_participating_contexts()
	count = 0
	for k, e in pairs(eclist_pec) do
		if e ~= oil.corba.idl.null then
			if NVUtil._is_equivalent(e, ec, e.getObjRef, ec.getObjRef) then
				return count+RTObject.ECOTHER_OFFSET
			end
		end
		count = count+1
	end
	return -1
end



-- RTCのアクティブ化
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return リターンコード
-- RTC_OK：アクティブ化成功
CORBA_RTCUtil.activate = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if ec_id == nil then
		ec_id = 0
	end
	if rtc == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local ec = CORBA_RTCUtil.get_actual_ec(rtc, ec_id)
	if ec == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(ec:activate_component(rtc))
end

-- RTCの非アクティブ化
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return リターンコード
-- RTC_OK：非アクティブ化成功
CORBA_RTCUtil.deactivate = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if ec_id == nil then
		ec_id = 0
	end
	if rtc == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local ec = CORBA_RTCUtil.get_actual_ec(rtc, ec_id)
	if ec == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(ec:deactivate_component(rtc))
end


-- RTCのリセット
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return リターンコード
-- RTC_OK：リセット成功
CORBA_RTCUtil.reset = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if ec_id == nil then
		ec_id = 0
	end
	if rtc == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local ec = CORBA_RTCUtil.get_actual_ec(rtc, ec_id)
	if ec == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(ec:reset_component(rtc))
end


-- RTCの状態取得
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return ret、state
-- ret true：状態取得成功
-- state 状態(取得に失敗した場合はCREATED_STATE)
CORBA_RTCUtil.get_state = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue
	if ec_id == nil then
		ec_id = 0
	end
	if rtc == oil.corba.idl.null then
		return false, LifeCycleState.CREATED_STATE
	end
	local ec = CORBA_RTCUtil.get_actual_ec(rtc, ec_id)

	if ec == oil.corba.idl.null then
		return false, LifeCycleState.CREATED_STATE
	end
	local state = ec:get_component_state(rtc)

	return true, NVUtil.getLifeCycleState(state)
end


-- RTCが非アクティブ状態かを確認
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return true：非アクティブ状態
CORBA_RTCUtil.is_in_inactive = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue

	if ec_id == nil then
		ec_id = 0
	end
	local ret, state = CORBA_RTCUtil.get_state(rtc, ec_id)
	if ret then
		if state == LifeCycleState.INACTIVE_STATE then
			return true
		end
	end

	return false
end

-- RTCがアクティブ状態かを確認
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return true：アクティブ状態
CORBA_RTCUtil.is_in_active = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue

	if ec_id == nil then
		ec_id = 0
	end
	local ret, state = CORBA_RTCUtil.get_state(rtc, ec_id)
	if ret then
		if state == LifeCycleState.ACTIVE_STATE then
			return true
		end
	end

	return false
end

-- RTCがエラー状態かを確認
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return true：エラー状態
CORBA_RTCUtil.is_in_error = function(rtc, ec_id)
	local Manager = require "openrtm.Manager"
	local LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue

	if ec_id == nil then
		ec_id = 0
	end
	local ret, state = CORBA_RTCUtil.get_state(rtc, ec_id)
	if ret then
		if state == LifeCycleState.ERROR_STATE then
			return true
		end
	end

	return false
end


-- 対象RTCのデフォルトの実行コンテキストでの実行周期を取得
-- @param rtc RTC
-- @return 実行周期
CORBA_RTCUtil.get_default_rate = function(rtc)
	local ec = CORBA_RTCUtil.get_actual_ec(rtc)
	return ec:get_rate()
end

-- 対象RTCのデフォルトの実行コンテキストでの実行周期を設定
-- @param rtc RTC
-- @param 実行周期
-- @return リターンコード
-- RTC_OK：設定成功
CORBA_RTCUtil.set_default_rate = function(rtc, rate)
	local ec = CORBA_RTCUtil.get_actual_ec(rtc)
	return ec:set_rate(rate)
end

-- 対象RTCのデフォルトの実行コンテキストでの実行周期を取得
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @return 実行周期
CORBA_RTCUtil.get_current_rate = function(rtc, ec_id)
	local ec = CORBA_RTCUtil.get_actual_ec(rtc, ec_id)
	return ec:get_rate()
end

-- 対象RTCのデフォルトの実行コンテキストでの実行周期を設定
-- @param rtc RTC
-- @param ec_id 実行コンテキストのID
-- @param 実行周期
-- @return リターンコード
-- RTC_OK：設定成功
CORBA_RTCUtil.set_current_rate = function(rtc, ec_id, rate)
	local ec = CORBA_RTCUtil.get_actual_ec(rtc, ec_id)
	return ec:set_rate(rate)
end


-- RTC1のデフォルトの実行コンテキストにRTC2を追加
-- @param localcomp RTC1
-- @param othercomp RTC2
-- @return リターンコード
CORBA_RTCUtil.add_rtc_to_default_ec = function(localcomp, othercomp)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if othercomp == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local ec = CORBA_RTCUtil.get_actual_ec(localcomp)
	if ec == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(ec:add_component(othercomp))
end


-- RTC1のデフォルトの実行コンテキストからRTC2を削除
-- @param localcomp RTC1
-- @param othercomp RTC2
-- @return リターンコード
CORBA_RTCUtil.remove_rtc_to_default_ec = function(localcomp, othercomp)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if othercomp == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local ec = CORBA_RTCUtil.get_actual_ec(localcomp)
	if ec == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(ec:remove_component(othercomp))
end


-- RTCのデフォルトの実行コンテキストにアタッチしている外部のRTCを取得
-- @param rtc RTC
-- @return RTC一覧
CORBA_RTCUtil.get_participants_rtc = function(rtc)
	local ec = CORBA_RTCUtil.get_actual_ec(rtc)
	if ec == oil.corba.idl.null then
		return {}
	end
	local profile = ec:get_profile()
	return profile.participants
end

-- RTCのポート名一覧を取得
-- @param rtc RTC
-- @return ポート名一覧
CORBA_RTCUtil.get_port_names = function(rtc)
	local names = {}
	if rtc == oil.corba.idl.null then
		return names
	end
	local ports = rtc:get_ports()
	for k,p in ipairs(ports) do
		local pp = p:get_port_profile()
		local s = pp.name
		table.insert(names, s)
	end
	return names
end


-- RTCのInPort名一覧を取得
-- @param rtc RTC
-- @return InPort名一覧
CORBA_RTCUtil.get_inport_names = function(rtc)
	local names = {}
	if rtc == oil.corba.idl.null then
		return names
	end
	local ports = rtc:get_ports()
	for k,p in ipairs(ports) do
		local pp = p:get_port_profile()
		local prop = Properties.new()
		NVUtil.copyToProperties(prop, pp.properties)
		if prop:getProperty("port.port_type") == "DataInPort" then
			local s = pp.name
			table.insert(names, s)
		end
	end
	return names
end


-- RTCのOutPort名一覧を取得
-- @param rtc RTC
-- @return OutPort名一覧
CORBA_RTCUtil.get_outport_names = function(rtc)
	local names = {}
	if rtc == oil.corba.idl.null then
		return names
	end
	local ports = rtc:get_ports()
	for k,p in ipairs(ports) do
		local pp = p:get_port_profile()
		local prop = Properties.new()
		NVUtil.copyToProperties(prop, pp.properties)
		if prop:getProperty("port.port_type") == "DataOutPort" then
			local s = pp.name
			table.insert(names, s)
		end
	end
	return names
end


-- RTCのサービスポート名一覧を取得
-- @param rtc RTC
-- @return サービスポート名一覧
CORBA_RTCUtil.get_svcport_names = function(rtc)
	local names = {}
	if rtc == oil.corba.idl.null then
		return names
	end
	local ports = rtc:get_ports()
	for k,p in ipairs(ports) do
		local pp = p:get_port_profile()
		local prop = Properties.new()
		NVUtil.copyToProperties(prop, pp.properties)
		if prop:getProperty("port.port_type") == "CorbaPort" then
			local s = pp.name
			table.insert(names, s)
		end
	end
	return names
end










-- ポート名からポートを取得
-- @param rtc RTC
-- @param port_name ポート名
-- @return ポート
CORBA_RTCUtil.get_port_by_name = function(rtc, port_name)
	if rtc == oil.corba.idl.null then
		return oil.corba.idl.null
	end
	local ports = rtc:get_ports()
	for k,p in ipairs(ports) do
		pp = p:get_port_profile()
		s = pp.name

		if port_name == s then
			return p
		end
	end

	return oil.corba.idl.null
end

-- ポートからコネクタ名一覧を取得
-- @param port ポート
-- @return コネクタ名一覧
CORBA_RTCUtil.get_connector_names_by_portref = function(port)
	local names = {}
	if port == oil.corba.idl.null then
		return names
	end
	local conprof = port:get_connector_profiles()
	for k,c in ipairs(conprof) do
		table.insert(names, c.name)
	end
	return names
end

-- RTCとポート名からコネクタ名一覧を取得
-- @param RTC rtc
-- @param port_name ポート名
-- @return コネクタ名一覧
CORBA_RTCUtil.get_connector_names = function(rtc, port_name)
	local names = {}
	local port = CORBA_RTCUtil.get_port_by_name(rtc, port_name)
	if port == oil.corba.idl.null then
		return names
	end
	local conprof = port:get_connector_profiles()
	for k,c in ipairs(conprof) do
		table.insert(names, c.name)
	end
	return names
end

-- ポートからコネクタID一覧を取得
-- @param port ポート
-- @return コネクタID一覧
CORBA_RTCUtil.get_connector_ids_by_portref = function(port)
	local ids = {}
	if port == oil.corba.idl.null then
		return ids
	end
	local conprof = port:get_connector_profiles()
	for k,c in ipairs(conprof) do
		table.insert(ids, c.connector_id)
	end
	return ids
end

-- RTCとポート名からコネクタID一覧を取得
-- @param RTC rtc
-- @param port_name ポート名
-- @return コネクタID一覧
CORBA_RTCUtil.get_connector_ids = function(rtc, port_name)
	local ids = {}
	local port = CORBA_RTCUtil.get_port_by_name(rtc, port_name)
	if port == oil.corba.idl.null then
		return ids
	end
	local conprof = port:get_connector_profiles()
	for k,c in ipairs(conprof) do
		table.insert(ids, c.connector_id)
	end
	return ids
end



-- コネクタプロファイルの生成
-- @param name コネクタ名
-- @param prop_arg 設定
-- データフロー型はデフォルトでpush
-- インターフェース型はデフォルトでdata_service
-- @param port0 ポート0
-- @param port1 ポート1
-- @return コネクタプロファイル
CORBA_RTCUtil.create_connector = function(name, prop_arg, port0, port1)
	local prop = prop_arg
	local conn_prof = {name=name, connector_id="", ports={port0, port1}, properties={}}


	if tostring(prop:getProperty("dataport.dataflow_type")) == "" then
		prop:setProperty("dataport.dataflow_type","push")
	end



	if tostring(prop:getProperty("dataport.interface_type")) == "" then
		prop:setProperty("dataport.interface_type","data_service")
	end


	conn_prof.properties = {}
	NVUtil.copyFromProperties(conn_prof.properties, prop)

	return conn_prof
end

-- 指定ポート同士が接続済みかを確認
-- @param localport ポート1
-- @param otherport ポート2
-- @return true：接続済み
CORBA_RTCUtil.already_connected = function(localport, otherport)
	local conprof = localport:get_connector_profiles()
	for k,c in ipairs(conprof) do
		for k,p in ipairs(c.ports) do
			if NVUtil._is_equivalent(p, otherport, p.getPortRef, otherport.getPortRef) then
				return true
			end
		end
	end

	return false
end


-- ポートの接続
-- @param name コネクタ名
-- @param prop 設定
-- @param port0 ポート0
-- @param port1 ポート1
-- @return リターンコード
-- RTC_OK：接続成功
CORBA_RTCUtil.connect = function(name, prop, port0, port1)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if port0 == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	if port1 == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	if NVUtil._is_equivalent(port0, port1, port0.getPortRef, port1.getPortRef) then
		return ReturnCode_t.BAD_PARAMETER
	end
	local cprof = CORBA_RTCUtil.create_connector(name, prop, port0, port1)
	
	local ret, prof = port0:connect(cprof)
	ret = NVUtil.getReturnCode(ret)
	
	--print(ret)
	return ret
end


-- 複数のポートを接続
-- @param name コネクタ名
-- @param prop 設定
-- @param port 接続元のポート
-- @param target_ports 接続先のポート一覧
-- @param リターンコード
-- RTC_OK：すべてのコネクタが接続成功
-- BAD_PARAMETER：いずれかのコネクタが接続失敗
CORBA_RTCUtil.connect_multi = function(name, prop, port, target_ports)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	local ret = ReturnCode_t.RTC_OK
	if port == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	for k,p in ipairs(target_ports) do
		if p == oil.corba.idl.null then
			ret =  ReturnCode_t.BAD_PARAMETER
		else
			if NVUtil._is_equivalent(p, port, p.getPortRef, port.getPortRef) then
				ret =  ReturnCode_t.BAD_PARAMETER
			else
				if CORBA_RTCUtil.already_connected(port, p) then
					ret =  ReturnCode_t.BAD_PARAMETER
				else
					if ReturnCode_t.RTC_OK ~= CORBA_RTCUtil.connect(name, prop, port, p) then
						ret =  ReturnCode_t.BAD_PARAMETER
					end
				end
			end
		end
	end


	return ret
end

-- ポート検索用関数オブジェクトの初期化
-- @param name ポート名
-- @return ポート検索用関数オブジェクト
CORBA_RTCUtil.find_port = function(name)
	local obj = {}
	obj._name = name


	-- ポート検索用関数
	-- @param self 自身のオブジェクト
	-- @param p 比較対象のポート
	-- @return true：一致
	local call_func = function(self, p)
		local prof = p:get_port_profile()
		local c = prof.name

		return (self._name == c)
	end
	setmetatable(obj, {__call=call_func})

	return obj
end


-- ポート名指定でコネクタを接続
-- @param name コネクタ名
-- @param prop 設定
-- @param rtc0 RTC0
-- @param port_name0 RTC0の保持するポート名
-- @param rtc1 RTC1
-- @param port_name1 RTC1の保持するポート名
-- @return リターンコード
-- RTC_OK：接続成功
-- BAD_PARAMETER：ポートが存在しない場合など
CORBA_RTCUtil.connect_by_name = function(name, prop, rtc0, port_name0, rtc1, port_name1)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if rtc0 == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	if rtc1 == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end

	local port0 = CORBA_RTCUtil.get_port_by_name(rtc0, port_name0)
	if port0 == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end

	local port1 = CORBA_RTCUtil.get_port_by_name(rtc1, port_name1)
	if port1 == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	
	return CORBA_RTCUtil.connect(name, prop, port0, port1)
end

-- コネクタ切断
-- @param connector_prof コネクタプロファイル
-- @return リターンコード
-- RTC_OK：切断成功
CORBA_RTCUtil.disconnect = function(connector_prof)
	local ports = connector_prof.ports
	return CORBA_RTCUtil.disconnect_by_portref_connector_id(ports[1], connector_prof.connector_id)
end


-- コネクタ名指定でコネクタ切断
-- @param port_ref ポート
-- @param conn_name コネクタ名
-- @return リターンコード
-- RTC_OK：切断成功
-- BAD_PARAMETER：コネクタが存在しない場合など
CORBA_RTCUtil.disconnect_by_portref_connector_name = function(port_ref, conn_name)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if port_ref == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local conprof = port_ref:get_connector_profiles()
	for k,c in ipairs(conprof) do
		if c.name == conn_name then
			return CORBA_RTCUtil.disconnect(c)
		end
	end
	return ReturnCode_t.BAD_PARAMETER
end


-- ポート名、コネクタ名指定でコネクタ切断
-- @param port_name ポート名
-- RTCをrtcloc、rtcname形式で指定する
-- rtcname://localhost/test.host_cxt/ConsoleIn0.out
-- @param conn_name コネクタ名
-- @return リターンコード
-- RTC_OK：切断成功
-- BAD_PARAMETER：コネクタが存在しない場合など
CORBA_RTCUtil.disconnect_by_portname_connector_name = function(port_name, conn_name)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	local port_ref = CORBA_RTCUtil.get_port_by_url(port_name)
	if port_ref == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end


	local conprof = port_ref:get_connector_profiles()
	for k,c in pairs(conprof) do
		if c.name == conn_name then
			return CORBA_RTCUtil.disconnect(c)
		end
	end

	return ReturnCode_t.BAD_PARAMETER
end


-- コネクタID指定でコネクタ切断
-- @param port_ref ポート
-- @param conn_name コネクタ名
-- @return リターンコード
-- RTC_OK：切断成功
CORBA_RTCUtil.disconnect_by_portref_connector_id = function(port_ref, conn_id)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if port_ref == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(port_ref:disconnect(conn_id))
end


-- ポート名、コネクタID指定でコネクタ切断
-- @param port_name ポート名
-- RTCをrtcloc、rtcname形式で指定する
-- rtcname://localhost/test.host_cxt/ConsoleIn0.out
-- @param conn_name コネクタ名
-- @return リターンコード
-- RTC_OK：切断成功
CORBA_RTCUtil.disconnect_by_portname_connector_id = function(port_name, conn_id)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	local port_ref = CORBA_RTCUtil.get_port_by_url(port_name)
	if port_ref == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end

	return NVUtil.getReturnCode(port_ref:disconnect(conn_id))
end

-- 全コネクタ切断
-- @param port_ref ポート
-- @return リターンコード
-- RTC_OK：切断成功
CORBA_RTCUtil.disconnect_all_by_ref = function(port_ref)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if port_ref == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(port_ref:disconnect_all())
end

-- ポート名、全コネクタ切断
-- @param port_name ポート名
-- RTCをrtcloc、rtcname形式で指定する
-- rtcname://localhost/test.host_cxt/ConsoleIn0.out
-- @return リターンコード
-- RTC_OK：切断成功
CORBA_RTCUtil.disconnect_all_by_name = function(port_name)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	local port_ref = CORBA_RTCUtil.get_port_by_url(port_name)
	if port_ref == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	return NVUtil.getReturnCode(port_ref:disconnect_all())
end


-- rtcloc、rtcname形式でポートを取得する
-- @param port_name ポート名
-- RTCをrtcloc、rtcname形式で指定する
-- rtcname://localhost/test.host_cxt/ConsoleIn0.out
-- @return ポート
CORBA_RTCUtil.get_port_by_url = function(port_name)
	local Manager = require "openrtm.Manager"
	local mgr = Manager:instance()
	local nm = mgr:getNaming()
	local p = StringUtil.split(port_name, "%.")
	if #p < 2 then
		return oil.corba.idl.null
	end

	local tmp = StringUtil.split(port_name, "%.")
	tmp[#tmp] = nil

	--print(StringUtil.flatten(tmp, "%."))
	local rtcs = nm:string_to_component(StringUtil.flatten(tmp, "%."))

	if #rtcs < 1 then
		return oil.corba.idl.null
	end
	local pn = StringUtil.split(port_name, "/")

	return CORBA_RTCUtil.get_port_by_name(rtcs[1],pn[#pn])
end


-- ポート1と接続しているポートとポート2が一致した場合にコネクタを切断
-- @param localport ポート1
-- @param othername ポート2
-- @return リターンコード
-- RTC_OK：切断成功
-- BAD_PARAMETER：接続していなかった場合など
CORBA_RTCUtil.disconnect_by_port_name = function(localport, othername)
	local Manager = require "openrtm.Manager"
	local ReturnCode_t  = Manager._ReturnCode_t
	if localport == oil.corba.idl.null then
		return ReturnCode_t.BAD_PARAMETER
	end
	local prof = localport:get_port_profile()
	if prof.name == othername then
		
		return ReturnCode_t.BAD_PARAMETER
	end

	local conprof = localport:get_connector_profiles()
	for k,c in ipairs(conprof) do
		for k2,p in ipairs(c.ports) do
			if p ~= oil.corba.idl.null then
				local pp = p:get_port_profile()
				--print(pp.name,othername)
				if pp.name == othername then
					return CORBA_RTCUtil.disconnect(c)
				end
			end
		end
	end
	return ReturnCode_t.BAD_PARAMETER
end

-- コンフィギュレーションセットをプロパティ形式で取得
-- @param rtc RTC
-- @param conf_name コンフィギュレーションセット名
-- @return コンフィギュレーションセット(プロパティ形式)
CORBA_RTCUtil.get_configuration = function(rtc, conf_name)
	local conf = rtc:get_configuration()

	local confset = conf:get_configuration_set(conf_name)
	local confData = confset.configuration_data
	local prop = Properties.new()
	NVUtil.copyToProperties(prop, confData)
	return prop
end

-- コンフィギュレーションパラメータの取得
-- @param rtc RTC
-- @param confset_name コンフィギュレーションセット名
-- @param value_name パラメータ名
-- @return パラメータ
CORBA_RTCUtil.get_parameter_by_key = function(rtc, confset_name, value_name)
	local conf = rtc:get_configuration()


	local confset = conf:get_configuration_set(confset_name)
	local confData = confset.configuration_data
	local prop = Properties.new()
	NVUtil.copyToProperties(prop, confData)
	return prop:getProperty(value_name)
end


-- アクティブなコンフィギュレーションセット名を取得
-- @param rtc RTC
-- @return コンフィギュレーションセット名
CORBA_RTCUtil.get_active_configuration_name = function(rtc)
	local conf = rtc:get_configuration()
	local confset = conf:get_active_configuration_set()
	return confset.id
end


-- アクティブなコンフィギュレーションセットをプロパティ形式で取得
-- @param rtc RTC
-- @return コンフィギュレーションセット(プロパティ形式)
CORBA_RTCUtil.get_active_configuration = function(rtc)
	local conf = rtc:get_configuration()

	local confset = conf:get_active_configuration_set()
	local confData = confset.configuration_data
	local prop = Properties.new()
	NVUtil.copyToProperties(prop, confData)
	return prop
end


-- コンフィギュレーションパラメータの設定
-- @param rtc RTC
-- @param confset_name コンフィギュレーションセット名
-- @param value_name パラメータ名
-- @param value 設定する値
-- @return true:設定成功
CORBA_RTCUtil.set_configuration = function(rtc, confset_name, value_name, value)
	local conf = rtc:get_configuration()

	local confset = conf:get_configuration_set(confset_name)

	CORBA_RTCUtil.set_configuration_parameter(conf, confset, value_name, value)

	conf:activate_configuration_set(confset_name)
	return true
end


-- アクティブなコンフィギュレーションセットのパラメータを設定
-- @param rtc RTC
-- @param value_name パラメータ名
-- @param value 設定する値
-- @return true:設定成功
CORBA_RTCUtil.set_active_configuration = function(rtc, value_name, value)
	local conf = rtc:get_configuration()

	local confset = conf:get_active_configuration_set()
	CORBA_RTCUtil.set_configuration_parameter(conf, confset, value_name, value)

	conf:activate_configuration_set(confset.id)
	return true
end


-- コンフィギュレーションパラメータ設定
-- @param conf コンフィギュレーション
-- @param confset コンフィギュレーションセット
-- @param value_name パラメータ名
-- @param value 設定する値
-- @return true:設定成功
CORBA_RTCUtil.set_configuration_parameter = function(conf, confset, value_name, value)
	local confData = confset.configuration_data
	local prop = Properties.new()
	NVUtil.copyToProperties(prop, confData)
	prop:setProperty(value_name,value)
	NVUtil.copyFromProperties(confData,prop)
	confset.configuration_data = confData
	conf:set_configuration_set_values(confset)
	return true
end


return CORBA_RTCUtil
