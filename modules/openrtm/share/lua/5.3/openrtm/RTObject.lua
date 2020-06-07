---------------------------------
--! @file RTObject.lua
--! @brief RTC基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local RTObject= {}
--_G["openrtm.RTObject"] = RTObject

local oil = require "oil"
local PortAdmin = require "openrtm.PortAdmin"
local Properties = require "openrtm.Properties"
local ConfigAdmin = require "openrtm.ConfigAdmin"
local SdoServiceAdmin = require "openrtm.SdoServiceAdmin"
local SdoConfiguration = require "openrtm.SdoConfiguration"
local Configuration_impl = SdoConfiguration.Configuration_impl
local ComponentActionListener = require "openrtm.ComponentActionListener"
local ComponentActionListeners = ComponentActionListener.ComponentActionListeners
local PortConnectListener = require "openrtm.PortConnectListener"
local PortConnectListeners = PortConnectListener.PortConnectListeners
local ManagerConfig = require "openrtm.ManagerConfig"
local ExecutionContextBase = require "openrtm.ExecutionContextBase"
local ExecutionContextFactory = ExecutionContextBase.ExecutionContextFactory
local StringUtil = require "openrtm.StringUtil"
local NVUtil = require "openrtm.NVUtil"
local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"
local RTCUtil = require "openrtm.RTCUtil"
local PreComponentActionListenerType = ComponentActionListener.PreComponentActionListenerType
local PostComponentActionListenerType = ComponentActionListener.PostComponentActionListenerType
local PortActionListenerType = ComponentActionListener.PortActionListenerType
local ExecutionContextActionListenerType = ComponentActionListener.ExecutionContextActionListenerType
local PreComponentActionListener = ComponentActionListener.PreComponentActionListener
local PostComponentActionListener = ComponentActionListener.PostComponentActionListener
local PortActionListener = ComponentActionListener.PortActionListener
local ExecutionContextActionListener = ComponentActionListener.ExecutionContextActionListener
local ComponentActionListeners = ComponentActionListener.ComponentActionListeners

local uuid = require "uuid"


RTObject.ECOTHER_OFFSET = 1000


local default_conf = {
  ["implementation_id"]="",
  ["type_name"]="",
  ["description"]="",
  ["version"]="",
  ["vendor"]="",
  ["category"]="",
  ["activity_type"]="",
  ["max_instance"]="",
  ["language"]="",
  ["lang_type"]="",
  ["conf"]=""}



local ec_copy = {}

-- 実行コンテキストのリストを連結する関数オブジェクト初期化
-- @param eclist 連結先のリスト
-- @return 実行コンテキストのリストを連結する関数オブジェクト
ec_copy.new = function(eclist)
	local obj = {}
	obj._eclist = eclist
	-- 実行コンテキストのリストを連結する
	-- @param self 自身のオブジェクト
	-- @param ecs 連結元のリスト
	local call_func = function(self, ecs)
		if ecs ~= nil then
			table.insert(self._eclist, ecs)
		end
	end
	setmetatable(obj, {__call=call_func})
	return obj
end



local ec_find = {}

-- 実行コンテキストのオブジェクトリファレンスが一致するかを確認する関数オブジェクト初期化
-- @param _ec 実行コンテキスト
-- @return 関数オブジェクト
ec_find.new = function(_ec)
	local obj = {}
	obj._ec = _ec


	-- 実行コンテキストのオブジェクトリファレンスが一致するかを確認する
	-- @param self 自身のオブジェクト
	-- @param ecs 実行コンテキスト
	-- @return true：一致、false：不一致
	local call_func = function(self, ecs)
		local ret = false
		local success, exception = oil.pcall(
			function()
				if ecs ~= nil then

					--print(#self._ec, #ecs)
					--for k, v in pairs(self._ec) do
					--	print( k, v )
					--end
					--print(self._ec:get_profile())
					--print(self._ec, ecs)
					ret = NVUtil._is_equivalent(self._ec, ecs, self._ec.getObjRef, ecs.getObjRef)
					--local Manager = require "openrtm.Manager"
					--local orb = Manager:instance():getORB()
					--ret = (orb:tostring(self._ec) == orb:tostring(ec))
					return
				end
			end)
		if not success then
			print(exception)
			return false
		end

		return ret
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


local svc_name = function(_id)
	local obj = {}
	obj._id = _id

	local call_func = function(self, prof)
		return (self._id == prof.id)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

-- RTC基底オブジェクト初期化
-- @param manager マネージャ
-- @return RTC
RTObject.new = function(manager)

	local obj = {}

	--print(manager)
	obj._manager = manager
	obj._orb = obj._manager:getORB()
	--print(obj._orb)
	obj._portAdmin = PortAdmin.new(obj._manager:getORB())
	obj._rtcout = obj._manager:getLogbuf("rtobject")
	obj._created = true
	obj._properties = Properties.new({defaults_map=default_conf})
	--print(obj._properties:getNode("conf"),type(obj._properties:getNode("conf")))
	obj._configsets = ConfigAdmin.new(obj._properties:getNode("conf"))
	obj._profile = {instance_name="",type_name="",
				  description="description",version="0", vendor="",
				  category="",port_profiles={},
				  parent=oil.corba.idl.null,properties={
				  {name="implementation_id",value=""}, {name="type_name",value=""},
				  {name="description",value=""},{name="version",value=""},
				  {name="vendor",value=""},{name="category",value=""},
				  {name="activity_type",value=""},{name="max_instance",value=""},
				  {name="language",value=""},{name="lang_type",value=""},
				  {name="instance_name",value=""}
				  }
				  }
	obj._sdoservice = SdoServiceAdmin.new(obj)
	obj._SdoConfigImpl = Configuration_impl.new(obj._configsets,obj._sdoservice)
	obj._SdoConfig = obj._SdoConfigImpl:getObjRef()
	obj._execContexts = {}

	obj._sdoOwnedOrganizations = {}
	obj._sdoSvcProfiles = {}
	obj._sdoOrganization = {}
	obj._sdoStatus = {}
	obj._ecMine  = {}
	obj._ecOther = {}
	obj._eclist  = {}
	obj._exiting = false
	obj._readAll = false
	obj._writeAll = false
	obj._readAllCompletion = false
	obj._writeAllCompletion = false
	obj._inports = {}
	obj._outports = {}
	obj._actionListeners = ComponentActionListeners.new()
	obj._portconnListeners = PortConnectListeners.new()
	obj._svr = nil

	obj._ReturnCode_t = obj._orb.types:lookup("::RTC::ReturnCode_t").labelvalue

	-- 初期化時のコールバック関数
	-- @return リターンコード
	function obj:onInitialize()
		self._rtcout:RTC_TRACE("onInitialize()")
		return self._ReturnCode_t.RTC_OK
	end
	-- 終了時のコールバック関数
	-- @return リターンコード
	function obj:onFinalize()
		self._rtcout:RTC_TRACE("onFinalize()")
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行コンテキスト開始時のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onStartup(ec_id)
		self._rtcout:RTC_TRACE("onStartup("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行コンテキスト停止時のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onShutdown(ec_id)
		self._rtcout:RTC_TRACE("onShutdown("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- アクティブ状態遷移後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onActivated(ec_id)
		self._rtcout:RTC_TRACE("onActivated("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- 非アクティブ状態遷移後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onDeactivated(ec_id)
		self._rtcout:RTC_TRACE("onDeactivated("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- アクティブ状態で実行コンテキストにより駆動されるコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onExecute(ec_id)
		self._rtcout:RTC_TRACE("onExecute("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- エラー状態遷移時のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onAborting(ec_id)
		self._rtcout:RTC_TRACE("onAborting("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- エラー状態で実行コンテキストにより駆動されるコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onError(ec_id)
		self._rtcout:RTC_TRACE("onError("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- リセット実行時のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onReset(ec_id)
		self._rtcout:RTC_TRACE("onReset("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- 状態更新時のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onStateUpdate(ec_id)
		self._rtcout:RTC_TRACE("onStateUpdate("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行周期変更後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:onRateChanged(ec_id)
		self._rtcout:RTC_TRACE("onRateChanged("..ec_id..")")
		return self._ReturnCode_t.RTC_OK
	end
	-- 初期化
	-- @return リターンコード
	function obj:initialize()
		self._rtcout:RTC_TRACE("initialize()")
		self:createRef()
		local ec_args_ = {}
		if self:getContextOptions(ec_args_) ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Valid EC options are not available. Aborting")
			return self._ReturnCode_t.BAD_PARAMETER
		end
		if self:createContexts(ec_args_) ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("EC creation failed. Maybe out of resources. Aborting.")
			return self._ReturnCode_t.BAD_PARAMETER
		end
		--self._rtcout:RTC_INFO(#self._ecMine.." execution context"..toSTR_(self._ecMine).." created.")
		local ret_ = self:on_initialize()
		self._created = false
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("on_initialize() failed.")
			return ret_
		end
		self._rtcout:RTC_DEBUG("on_initialize() was properly done.")
		for idx_, ec_ in ipairs(self._ecMine) do
			self._rtcout:RTC_DEBUG("EC"..idx_.." starting.")
			ec_:start()
		end
		self._sdoservice:init(self)
		return self._ReturnCode_t.RTC_OK
	end
	-- 終了
	-- @return リターンコード
	function obj:finalize()
		self._rtcout:RTC_TRACE("finalize()")
		if self._created or not self._exiting then
			return self._ReturnCode_t.PRECONDITION_NOT_MET
		end
		if #self._ecOther ~= 0 then
			self._ecOther = {}
		end
		local ret = self:on_finalize()
		self:shutdown()
		return ret
	end
	-- プロパティ取得
	-- @return プロパティ
	function obj:getProperties()
		self._rtcout:RTC_TRACE("getProperties()")
		return self._properties
	end
	-- インスタンス名取得
	-- @return インスタンス名
	function obj:getInstanceName()
		self._rtcout:RTC_TRACE("getInstanceName()")
		return self._profile.instance_name
	end
	-- インスタンス名設定
	-- @param instance_name インスタンス名
	function obj:setInstanceName(instance_name)
		self._rtcout:RTC_TRACE("setInstanceName("..instance_name..")")
		self._properties:setProperty("instance_name",instance_name)
		self._profile.instance_name = self._properties:getProperty("instance_name")
	end
	-- 型名取得
	-- @return 型名
	function obj:getTypeName()
		self._rtcout:RTC_TRACE("getTypeName()")
		return self._profile.type_name
	end
	-- カテゴリ名取得
	-- @return カテゴリ名
	function obj:getCategory()
		self._rtcout:RTC_TRACE("getCategory()")
		return self._profile.category
	end
	-- プロパティ設定
	-- @param prop プロパティ
	function obj:setProperties(prop)
		self._rtcout:RTC_TRACE("setProperties()")
		self._properties:mergeProperties(prop)
		self._profile.instance_name = self._properties:getProperty("instance_name")
		self._profile.type_name = self._properties:getProperty("type_name")
		self._profile.description = self._properties:getProperty("description")
		self._profile.version = self._properties:getProperty("version")
 		self._profile.vendor = self._properties:getProperty("vendor")
		self._profile.category = self._properties:getProperty("category")
	end

	-- オブジェクトリファレンス取得
	-- @return オブジェクトリファレンス
	function obj:getObjRef()
		self._rtcout:RTC_TRACE("getObjRef()")
		return self._objref
	end

	-- Manager全体で設定したグローバルな実行コンテキストの設定取得
	-- @param global_ec_props 実行コンテキストの設定
	-- @return リターンコード
	function obj:getGlobalContextOptions(global_ec_props)
		self._rtcout:RTC_TRACE("getGlobalContextOptions()")

		local prop_ = self._properties:findNode("exec_cxt.periodic")
		if prop_ == nil then
		  self._rtcout:RTC_WARN("No global EC options found.")
		  return self._ReturnCode_t.RTC_ERROR
		end
		--print(prop_)

		self._rtcout:RTC_DEBUG("Global EC options are specified.")
		self._rtcout:RTC_DEBUG(prop_)
		self:getInheritedECOptions(global_ec_props)
		global_ec_props:mergeProperties(prop_)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTC固有の実行コンテキストの設定取得
	-- @param ec_args 実行コンテキストの設定
	-- @return リターンコード
	function obj:getPrivateContextOptions(ec_args)
		self._rtcout:RTC_TRACE("getPrivateContextOptions()")
		if not self._properties.findNode("execution_contexts") then
			self._rtcout:RTC_DEBUG("No component specific EC specified.")
			return self._ReturnCode_t.RTC_ERROR
		end
		return self._ReturnCode_t.RTC_OK
	end
	-- 引数に実行コンテキストのオプションを追加する
	-- @param default_opts オプション
	-- @return リターンコード
	function obj:getInheritedECOptions(default_opts)
		self._rtcout:RTC_TRACE("getPrivateContextOptions()")
		return self._ReturnCode_t.RTC_OK
	end

	-- 実行コンテキストのオプション取得
	-- @param ec_args 実行コンテキストのオプション
	-- @return リターンコード
	function obj:getContextOptions(ec_args)
		self._rtcout:RTC_DEBUG("getContextOptions()")
		local global_props_ = Properties.new()
		local ret_global_  = self:getGlobalContextOptions(global_props_)
		local ret_private_ = self:getPrivateContextOptions(ec_args)
		if ret_global_ ~= self._ReturnCode_t.RTC_OK and ret_private_ ~= self._ReturnCode_t.RTC_OK then
			return self._ReturnCode_t.RTC_ERROR
		end
		--print(ret_global_, ret_private_)
		if ret_global_ == self._ReturnCode_t.RTC_OK and ret_private_ ~= self._ReturnCode_t.RTC_OK then
			table.insert(ec_args,global_props_)
		end
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行コンテキスト生成
	-- @param ec_args オプション
	-- @return リターンコード
	function obj:createContexts(ec_args)


		local ret_ = self._ReturnCode_t.RTC_OK
		local avail_ec_ = ExecutionContextFactory:instance():getIdentifiers()

		--print(#ec_args)
		for i,ec_arg_ in ipairs(ec_args) do
			local ec_type_ = ec_arg_:getProperty("type")
			local ec_name_ = ec_arg_:getProperty("name")
			--print(ec_arg_)
			local ret_aec = false
			for i,aec in ipairs(avail_ec_) do
				--print(aec)
				if ec_type_ == aec then
					ret_aec = true

					break
				end
			end
			if not ret_aec then
				self._rtcout:RTC_WARN("EC "..ec_type_.." is not available.")
				self._rtcout:RTC_DEBUG("Available ECs: "..
									StringUtil.flatten(avail_ec_))
			else
				local ec_ = ExecutionContextFactory:instance():createObject(ec_type_)
				ec_:init(ec_arg_)
				table.insert(self._eclist, ec_)
				ec_:bindComponent(self)
			end
		end

		if #self._eclist == 0 then
			default_opts = Properties.new()
			ec_type_ = "PeriodicExecutionContext"
			local ec_ = ExecutionContextFactory:instance():createObject(ec_type_)
			ec_:init(default_opts)
			table.insert(self._eclist, ec_)
			ec_:bindComponent(self)
		end
		return ret_
	end
	-- 初期化時コールバック関数実行
	-- @return リターンコード
	function obj:on_initialize()
		self._rtcout:RTC_TRACE("on_initialize()")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnInitialize(0)
				self._rtcout:RTC_DEBUG("Calling onInitialize().")
				ret = self:onInitialize()
				if ret ~= self._ReturnCode_t.RTC_OK then
					self._rtcout:RTC_ERROR("onInitialize() returns an ERROR ("..ret..")")
				else
					self._rtcout:RTC_DEBUG("onInitialize() succeeded.")
				end
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		local active_set = self._properties:getProperty("configuration.active_config",
                                              "default")
		if self._configsets:haveConfig(active_set) then
			self._rtcout:RTC_DEBUG("Active configuration set: "..active_set.." exists.")
			self._configsets:activateConfigurationSet(active_set)
			self._configsets:update(active_set)
			self._rtcout:RTC_INFO("Initial active configuration set is "..active_set..".")
		else
			self._rtcout:RTC_DEBUG("Active configuration set: "..active_set.." does not exists.")
			self._configsets:activateConfigurationSet("default")
			self._configsets:update("default")
			self._rtcout:RTC_INFO("Initial active configuration set is default-set.")
		end
		self:postOnInitialize(0)
		return ret
	end

	-- 実行コンテキストの関連付け
	-- @param exec_context 実行コンテキスト
	-- @return 実行コンテキストのID
	function obj:bindContext(exec_context)
		--print(exec_context)
		self._rtcout:RTC_TRACE("bindContext()")
		if exec_context == nil then
			return -1
		end
		for i =1,#self._ecMine do
			if self._ecMine[i] == nil then
				self._ecMine[i] = exec_context
				self:onAttachExecutionContext(i)
				return i-1
			end
		end
		table.insert(self._ecMine, exec_context)
		return #self._ecMine - 1
	end
	-- 実行コンテキスト開始時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_startup(ec_id)
		self._rtcout:RTC_TRACE("on_startup("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnStartup(ec_id)
				ret = self:onStartup(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnStartup(ec_id, ret)
		return ret
	end
	-- 実行コンテキスト停止時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_shutdown(ec_id)
		self._rtcout:RTC_TRACE("on_shutdown("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnShutdown(ec_id)
				ret = self:onShutdown(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnShutdown(ec_id, ret)
		return ret
	end
	-- アクティブ状態遷移後コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_activated(ec_id)
		self._rtcout:RTC_TRACE("on_activated("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		--print("on_activated1")
		local success, exception = oil.pcall(
			function()
				self:preOnActivated(ec_id)
				self._configsets:update()
				ret = self:onActivated(ec_id)
				self._portAdmin:activatePorts()
		end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnActivated(ec_id, ret)
		--print(type(ret))
		return ret
	end
	-- 非アクティブ状態遷移後コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_deactivated(ec_id)
		self._rtcout:RTC_TRACE("on_deactivated("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnDeactivated(ec_id)
				self._portAdmin:deactivatePorts()
				ret = self:onDeactivated(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnDeactivated(ec_id, ret)
		return ret
	end
	-- エラー状態遷移後コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_aborting(ec_id)
		self._rtcout:RTC_TRACE("on_aborting("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnAborting(ec_id)
				ret = self:onAborting(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnAborting(ec_id, ret)
		return ret
	end
	-- エラー状態時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_error(ec_id)
		self._rtcout:RTC_TRACE("on_error("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnError(ec_id)
				ret = self:onError(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self._configsets:update()
		self:postOnError(ec_id, ret)
		return ret
	end
	-- リセット実行時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_reset(ec_id)
		self._rtcout:RTC_TRACE("on_reset("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnReset(ec_id)
				ret = self:onReset(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnReset(ec_id, ret)
		return ret
	end
	-- アクティブ状態時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_execute(ec_id)
		self._rtcout:RTC_TRACE("on_execute("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				if self._readAll then
					self:readAll()
				end
				self:preOnExecute(ec_id)
				ret = self:onExecute(ec_id)
				if self._writeAll then
					self:writeAll()
				end
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnExecute(ec_id, ret)
		return ret
	end
	-- 状態更新時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_state_update(ec_id)
		self._rtcout:RTC_TRACE("on_state_update("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnStateUpdate(ec_id)
				ret = self:onStateUpdate(ec_id)
				self._configsets:update()
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end

		self:postOnStateUpdate(ec_id, ret)
		return ret
	end
	-- 実行周期変更時コールバック関数実行
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコード
	function obj:on_rate_changed(ec_id)
		self._rtcout:RTC_TRACE("on_rate_changed("..ec_id..")")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnRateChanged(ec_id)
				ret = self:onRateChanged(ec_id)
			end)
		if not success then
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnRateChanged(ec_id, ret)
		return ret
	end
	-- 全ポート読み込み
	function obj:readAll()
		self._rtcout:RTC_TRACE("readAll()")
    end
    -- 全ポート書き込み
	function obj:writeAll()
		self._rtcout:RTC_TRACE("writeAll()")
	end
	

	function obj:addPreComponentActionListener(listener_type, memfunc, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		local Noname = {}
		
		Noname.new = function(memfunc)
			local _obj = {}
			setmetatable(_obj, {__index=ComponentActionListener.PreComponentActionListener.new()})
			_obj._memfunc = memfunc
			function _obj:call(ec_id)
				self._memfunc(ec_id)
			end
			return _obj
		end

		listener = Noname.new(memfunc)
		self._actionListeners.preaction_[listener_type]:addListener(listener, autoclean)
		return listener
	end

	function obj:removePreComponentActionListener(listener_type, listener)
		self._actionListeners.preaction_[listener_type]:removeListener(listener)
	end


	function obj:addPostComponentActionListener(listener_type, memfunc, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		local Noname = {}
		
		Noname.new = function(memfunc)
			local _obj = {}
			setmetatable(_obj, {__index=ComponentActionListener.PostComponentActionListener.new()})
			_obj._memfunc = memfunc
			function _obj:call(ec_id)
				self._memfunc(ec_id)
			end
			return _obj
		end

		listener = Noname.new(memfunc)
		self._actionListeners.postaction_[listener_type]:addListener(listener, autoclean)
		return listener
	end

	function obj:removePostComponentActionListener(listener_type, listener)
		self._actionListeners.postaction_[listener_type]:removeListener(listener)
	end



	function obj:addPortActionListener(listener_type, memfunc, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		local Noname = {}
		Noname.new = function(memfunc)
			local _obj = {}
			setmetatable(_obj, {__index=ComponentActionListener.PortActionListener.new()})
			_obj._memfunc = memfunc
			function _obj:call(ec_id)
				self._memfunc(ec_id)
			end
			return _obj
		end

		listener = Noname.new(memfunc)
		self._actionListeners.portaction_[listener_type]:addListener(listener, autoclean)
		return listener
	end

	function obj:removePortActionListener(listener_type, listener)
		self._actionListeners.postaction_[listener_type]:removeListener(listener)
	end



	function obj:addExecutionContextActionListener(listener_type, memfunc, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		local Noname = {}
		Noname.new = function(memfunc)
			local _obj = {}
			setmetatable(_obj, {__index=ComponentActionListener.ExecutionContextActionListener.new()})
			_obj._memfunc = memfunc
			function _obj:call(ec_id)
				self._memfunc(ec_id)
			end
			return _obj
		end

		listener = Noname.new(memfunc)
		self._actionListeners.ecaction_[listener_type]:addListener(listener, autoclean)
		return listener
	end

	function obj:removeExecutionContextActionListener(listener_type, listener)
		self._actionListeners.ecaction_[listener_type]:removeListener(listener)
	end



	-- 初期化前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnInitialize(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_INITIALIZE]:notify(ec_id)
	end
	-- 終了前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnFinalize(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_FINALIZE]:notify(ec_id)
	end
	-- 実行コンテキスト開始前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnStartup(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_STARTUP]:notify(ec_id)
	end
	-- 実行コンテキスト停止前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnShutdown(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_SHUTDOWN]:notify(ec_id)
	end
	-- アクティブ化前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnActivated(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_ACTIVATED]:notify(ec_id)
	end
	-- 非アクティブ化前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnDeactivated(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_DEACTIVATED]:notify(ec_id)
	end
	-- エラー状態遷移前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnAborting(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_ABORTING]:notify(ec_id)
	end
	-- エラー状態コールバック関数実行前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnError(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_ERROR]:notify(ec_id)
	end
	-- リセット実行前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnReset(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_RESET]:notify(ec_id)
	end
	-- アクティブ状態コールバック関数実行前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnExecute(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_EXECUTE]:notify(ec_id)
	end
	-- 状態更新前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnStateUpdate(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_STATE_UPDATE]:notify(ec_id)
	end
	-- 実行周期変更前のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:preOnRateChanged(ec_id)
		self._actionListeners.preaction_[PreComponentActionListenerType.PRE_ON_RATE_CHANGED]:notify(ec_id)
	end

	-- 初期化後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnInitialize(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_INITIALIZE]:notify(ec_id, ret)
    end
	-- 終了後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnFinalize(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_FINALIZE]:notify(ec_id, ret)
    end
    -- 実行コンテキスト開始後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnStartup(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_STARTUP]:notify(ec_id, ret)
    end
    -- 実行コンテキスト停止後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnShutdown(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_SHUTDOWN]:notify(ec_id, ret)
    end
    -- アクティブ化後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnActivated(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_ACTIVATED]:notify(ec_id, ret)
    end
    -- 非アクティブ化後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnDeactivated(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_DEACTIVATED]:notify(ec_id, ret)
    end
    -- エラー状態遷移後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnAborting(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_ABORTING]:notify(ec_id, ret)
    end
    -- エラー状態コールバック関数実行後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnError(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_ERROR]:notify(ec_id, ret)
    end
    -- リセット実行後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnReset(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_RESET]:notify(ec_id, ret)
    end
    -- アクティブ状態コールバック関数実行後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnExecute(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_EXECUTE]:notify(ec_id, ret)
    end
    -- 状態更新後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnStateUpdate(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_STATE_UPDATE]:notify(ec_id, ret)
    end
    -- 実行周期変更後のコールバック関数
	-- @param ec_id 実行コンテキストのID
	function obj:postOnRateChanged(ec_id, ret)
		self._actionListeners.postaction_[PostComponentActionListenerType.POST_ON_RATE_CHANGED]:notify(ec_id, ret)
    end

	-- コンフィギュレーションパラメータの変数をバインド
	-- @param param_name パラメータ名
	-- @param var 変数
	-- @param def_val デフォルト値
	-- @param trans 変換関数
	-- @return true：バインド成功
	function obj:bindParameter(param_name, var, def_val, trans)
		self._rtcout:RTC_TRACE("bindParameter()")
		if trans == nil then
			trans = StringUtil.stringTo
		end
		--print(param_name, var, def_val, trans)
		self._configsets:bindParameter(param_name, var, def_val, trans)
		return true
	end

	-- コンフィギュレーション管理オブジェクト取得
	-- @return コンフィギュレーション管理オブジェクト
	function obj:getConfigService()
		return self._configsets
	end

	-- コンフィギュレーションパラメータ更新
	-- @param config_set コンフィギュレーションセット
	function obj:updateParameters(config_set)
		self._rtcout:RTC_TRACE("updateParameters("..config_set..")")
		self._configsets:update(config_set)
    end


	-- 実行コンテキスト取得
	-- @param ec_id 実行コンテキストのID
	-- @return 実行コンテキスト
	function obj:getExecutionContext(ec_id)
		return self:get_context(ec_id)
	end

	-- 実行コンテキスト取得
	-- @param ec_id 実行コンテキストのID
	-- @return 実行コンテキスト
	function obj:get_context(ec_id)

		self._rtcout:RTC_TRACE("get_context("..ec_id..")")
		ec_id = ec_id + 1
		if ec_id < RTObject.ECOTHER_OFFSET then
			if self._ecMine[ec_id] ~= nil then
				return self._ecMine[ec_id]
			else
				return oil.corba.idl.null
			end
		end


		local index = ec_id - ECOTHER_OFFSET

		if self._ecOther[index] ~= nil then
			return self._ecOther[index]
		end

		return oil.corba.idl.null
	end

	-- 自身がオーナーの実行コンテキスト一覧を取得
	-- @return 実行コンテキスト一覧
	function obj:get_owned_contexts()
		self._rtcout:RTC_TRACE("get_owned_contexts()")
		local execlist = {}
		CORBA_SeqUtil.for_each(self._ecMine, ec_copy.new(execlist))
		--print(#execlist)
		return execlist
	end

	-- 別のRTCがオーナーの実行コンテキスト一覧を取得
	-- @return 実行コンテキスト一覧
	function obj:get_participating_contexts()
		self._rtcout:RTC_TRACE("get_participating_contexts()")
		local execlist = {}
		CORBA_SeqUtil.for_each(self._ecOther, ec_copy.new(execlist))
		--print(#self._ecOther)
		return execlist
	end

	-- 実行コンテキストのIDを取得
	-- @param cxt 実行コンテキスト
	-- @return ID
	function obj:get_context_handle(cxt)
		self._rtcout:RTC_TRACE("get_context_handle()")

		--for i,v in ipairs(self._ecMine) do
		--	print(v)
		--end
		local num = CORBA_SeqUtil.find(self._ecMine, ec_find.new(cxt))
		--print(num)
		if num ~= -1 then
			return num-1
		end

		num = CORBA_SeqUtil.find(self._ecOther, ec_find.new(cxt))
		if num ~= -1 then
			return num-1 + 1000
		end

		return -1
	end

	-- ネームサーバー登録名取得
	-- @return ネームサーバー登録名
	function obj:getNamingNames()
		self._rtcout:RTC_TRACE("getNamingNames()")
		--print(self._properties)
		local ret_str = StringUtil.split(self._properties:getProperty("naming.names"), ",")
		local ret = {}
		for k, v in pairs(ret_str) do
			v = StringUtil.eraseHeadBlank(v)
			v = StringUtil.eraseTailBlank(v)
			table.insert(ret, v)
		end
		return ret
	end

	-- コンフィギュレーション取得
	-- @return コンフィギュレーション
	function obj:get_configuration()
		self._rtcout:RTC_TRACE("get_configuration()")
		if self._SdoConfig == nil then
			error(self._orb:newexcept{"SDOPackage::InterfaceNotImplemented",
				description="InterfaceNotImplemented: get_configuration"
			})
		end
		return self._SdoConfig
	end

	-- ポート追加
	-- @param port ポート
	-- @return true：登録成功、false：登録失敗
	function obj:addPort(port)
		self._rtcout:RTC_TRACE("addPort()")
		self._rtcout:RTC_TRACE("addPort(CorbaPort)")
		local propkey = "port.corbaport."
		local prop = self._properties:getNode(propkey)
		if prop ~= nil then
			self._properties:getNode(propkey):mergeProperties(self._properties:getNode("port.corba"))
		end

		port:init(self._properties:getNode(propkey))
		port:setOwner(self)


		return self._portAdmin:addPort(port)
	end



	-- インポート追加
	-- @param name ポート名
	-- @param inport インポート
	-- @return true：登録成功、false：登録失敗
	function obj:addInPort(name, inport)
		self._rtcout:RTC_TRACE("addInPort("..name..")")

		local propkey = "port.inport."..name
		local prop_ = Properties.new({prop=self._properties:getNode(propkey)})
		prop_:mergeProperties(self._properties:getNode("port.inport.dataport"))
		inport:init(prop_)

		inport:setOwner(self)
		inport:setPortConnectListenerHolder(self._portconnListeners)
		self:onAddPort(inport:getPortProfile())

		local ret = self._portAdmin:addPort(inport)

		if not ret then
			self._rtcout:RTC_ERROR("addInPort() failed.")
			return ret
		end


		table.insert(self._inports, inport)


		return ret
	end


	-- アウトポート追加
	-- @param name ポート名
	-- @param inport アウトポート
	-- @return true：登録成功、false：登録失敗
	function obj:addOutPort(name, outport)
		self._rtcout:RTC_TRACE("addOutPort("..name..")")

		local propkey = "port.outport."..name
		local prop_ = Properties.new({prop=self._properties:getNode(propkey)})
		prop_:mergeProperties(self._properties:getNode("port.outport.dataport"))
		outport:init(prop_)

		outport:setOwner(self)
		outport:setPortConnectListenerHolder(self._portconnListeners)
		self:onAddPort(outport:getPortProfile())

		local ret = self._portAdmin:addPort(outport)

		if not ret then
			self._rtcout:RTC_ERROR("addOutPort() failed.")
			return ret
		end


		table.insert(self._outports, outport)


		return ret
	end

	-- インポート削除
	-- @param name ポート名
	-- @param inport インポート
	-- @return true：削除成功、false：削除失敗
	function obj:removeInPort(port)
		self._rtcout:RTC_TRACE("removeInPort()")
		local ret = self:removePort(port)

		if ret ~= nil then
			for i, inport in ipairs(self._inports) do
				if port == inport then
					table.remove(self._inports, i)
					return true
				end
			end
		end
		return false
	end

	-- アウトポート削除
	-- @param name ポート名
	-- @param inport アウトポート
	-- @return true：削除成功、false：削除失敗
	function obj:removeOutPort(port)
		self._rtcout:RTC_TRACE("removeOutPort()")
		local ret = self:removePort(port)

		if ret ~= nil then
			for i, outport in ipairs(self._outports) do
				if port == outport then
					table.remove(self._outports, i)
					return true
				end
			end
		end
		return false
	end


	-- ポート削除
	-- @param port ポート
	-- @return true：削除成功、false：削除失敗
	function obj:removePort(port)
		self._rtcout:RTC_TRACE("removePort()")
		self:onRemovePort(port:getPortProfile())
		return self._portAdmin:removePort(port)
	end

	-- プロファイル取得
	-- @return プロファイル
	function obj:get_component_profile()
		self._rtcout:RTC_TRACE("get_component_profile()")

		local prop_ = {instance_name = self._properties:getProperty("instance_name"),
				 type_name = self._properties:getProperty("type_name"),
				 description = self._properties:getProperty("description"),
				 version = self._properties:getProperty("version"),
				 vendor = self._properties:getProperty("vendor"),
				 category = self._properties:getProperty("category"),
				 port_profiles = self._portAdmin:getPortProfileList(),
				 parent = self._profile.parent,
				 properties = self._profile.properties}
		NVUtil.copyFromProperties(self._profile.properties, self._properties)
		--print(oil.corba.idl.null)
		return prop_
	end

	-- ポート追加時のコールバック実行
	-- @param pprof ポートプロファイル
	function obj:onAddPort(pprof)
		self._actionListeners.portaction_[PortActionListenerType.ADD_PORT]:notify(pprof)
    end
    -- ポート削除時のコールバック実行
	-- @param pprof ポートプロファイル
	function obj:onRemovePort(pprof)
		self._actionListeners.portaction_[PortActionListenerType.REMOVE_PORT]:notify(pprof)
    end
    -- 実行コンテキストアタッチ時のコールバック実行
    -- @param ec_id 実行コンテキストのID
	function obj:onAttachExecutionContext(ec_id)
		
		self._actionListeners.ecaction_[ExecutionContextActionListenerType.EC_ATTACHED]:notify(ec_id)
    end
    -- 実行コンテキストデタッチ時のコールバック実行
    -- @param ec_id 実行コンテキストのID
	function obj:onDetachExecutionContext(pprof)
		self._actionListeners.ecaction_[ExecutionContextActionListenerType.EC_DETACHED]:notify(ec_id)
    end

	-- 生存確認
	-- @param exec_context 実行コンテキスト
	-- @return true：生存、false：消滅
	function obj:is_alive(exec_context)
		self._rtcout:RTC_TRACE("is_alive()")

		for i, ec in ipairs(self._ecMine) do
			--if exec_context:_is_equivalent(ec) then
			local Manager = require "openrtm.Manager"
			local orb = Manager:instance():getORB()

			if NVUtil._is_equivalent(exec_context, ec, exec_context.getObjRef, ec.getObjRef) then
				return true
			end
		end


		for i, ec in ipairs(self._ecOther) do
			if ec == nil then
				if NVUtil._is_equivalent(exec_context, ec, exec_context.getObjRef, ec.getObjRef) then
					return true
				end
			end
		end

		return false
	end

	-- RTCの終了実行
	-- @return リターンコード
	function obj:exit()
		self._rtcout:RTC_TRACE("exit()")
		if self._created then
			return self._ReturnCode_t.PRECONDITION_NOT_MET
		end
		if self._exiting then
			return self._ReturnCode_t.RTC_OK
		end

		for i, ec in ipairs(self._ecOther) do
			if not NVUtil._non_existent(ec) then
				ec:remove_component(self:getObjRef())
			end
		end

		self._exiting = true
		return self:finalize()
	end

	-- 実行コンテキストのアタッチ
	-- @param exec_context 実行コンテキスト
	-- @return ID
	function obj:attach_context(exec_context)
		local ECOTHER_OFFSET = RTObject.ECOTHER_OFFSET
		self._rtcout:RTC_TRACE("attach_context()")

		local ecs = exec_context
		if ecs == oil.corba.idl.null then
			return -1
		end
		
		
		for i,oec in ipairs(self._ecOther) do
			if oec == oil.corba.idl.null then
				self._ecOther[i] = ecs
				local ec_id = i + ECOTHER_OFFSET
				self:onAttachExecutionContext(ec_id)
				return ec_id
			end
		end
		table.insert(self._ecOther,ecs)
		local ec_id = tonumber(#self._ecOther - 1 + ECOTHER_OFFSET)
		self:onAttachExecutionContext(ec_id)
		return ec_id
	end
	-- 実行コンテキストのデタッチ
	-- @param ec_id 実行コンテキストのID
	-- @return リターンコードリターンコード
	function obj:detach_context(ec_id)
		ec_id = ec_id + 1
		local ECOTHER_OFFSET = RTObject.ECOTHER_OFFSET
    	self._rtcout:RTC_TRACE("detach_context(%d)", ec_id)
    	local len_ = #self._ecOther

		if (tonumber(ec_id) < tonumber(ECOTHER_OFFSET)) or (tonumber(ec_id - ECOTHER_OFFSET) > len_) then
			return self._ReturnCode_t.BAD_PARAMETER
		end
    
    	local index = tonumber(ec_id - ECOTHER_OFFSET)
		
    	if index < 0 or self._ecOther[index] == oil.corba.idl.null then
			return self._ReturnCode_t.BAD_PARAMETER
		end
    
   
    	self._ecOther[index] = oil.corba.idl.null
    	self:onDetachExecutionContext(ec_id)
		return self._ReturnCode_t.RTC_OK
	end

	-- ポート一覧取得
	-- @return ポート一覧
	function obj:get_ports()
		self._rtcout:RTC_TRACE("get_ports()")
		return self._portAdmin:getPortServiceList()
	end

	-- オブジェクトリファレンス生成
	function obj:createRef()
		self._svr = self._orb:newservant(self, nil, "IDL:openrtm.aist.go.jp/OpenRTM/DataFlowComponent:1.0")
		--print(type(self._svr))
		self._objref = RTCUtil.getReference(self._orb, self._svr, "IDL:openrtm.aist.go.jp/OpenRTM/DataFlowComponent:1.0")
	end

	-- 終了時コールバック実行
	-- @return リターンコード
	function obj:on_finalize()
		self._rtcout:RTC_TRACE("on_finalize()")
		local ret = self._ReturnCode_t.RTC_ERROR
		local success, exception = oil.pcall(
			function()
				self:preOnFinalize(0)
				ret = self:onFinalize()
			end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR(exception)
			ret = self._ReturnCode_t.RTC_ERROR
		end
		self:postOnFinalize(0, ret)
		return ret
	end

	-- 終了処理
	function obj:shutdown()
		self._rtcout:RTC_TRACE("shutdown()")
		local success, exception = oil.pcall(
			function()
				self:finalizePorts()
				self:finalizeContexts()
				--self._orb:deactivate(self._SdoConfigImpl)
				--self._orb:deactivate(self._objref)
				self._SdoConfigImpl:deactivate()
				if self._svr ~= nil then
					self._orb:deactivate(self._svr)
				end
				self._sdoservice:exit()
			end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR(exception)
		end

		if self._manager ~= nil then
			self._rtcout:RTC_DEBUG("Cleanup on Manager")
			self._manager:notifyFinalized(self)
		end

		self._actionListeners = nil
		self._portconnListeners = nil

	end

	-- 全ポートの終了
	function obj:finalizePorts()
		self._rtcout:RTC_TRACE("finalizePorts()")
		self._portAdmin:finalizePorts()
		self._inports = {}
		self._outports = {}
    end

	-- 全実行コンテキストの終了
	function obj:finalizeContexts()
		self._rtcout:RTC_TRACE("finalizeContexts()")

		for i,ec in ipairs(self._eclist) do
			ec:stop()
			local success, exception = oil.pcall(
				function()
					self._orb:deactivate(ec._svr)
				end)
			if not success then
			end
			ec:exit()
		end

		self._eclist = {}
	end

	function obj:addSdoServiceProvider(prof, provider)
		return self._sdoservice:addSdoServiceProvider(prof, provider)
	end

	function obj:removeSdoServiceProvider(id)
		return self._sdoservice:removeSdoServiceProvider(id)
	end

	function obj:addSdoServiceConsumer(prof)
		return self._sdoservice:addSdoServiceConsumer(prof)
	end

	function obj:removeSdoServiceConsumer(id)
		return self._sdoservice:removeSdoServiceConsumer(id)
	end


	function obj:get_sdo_service(_id)
		self._rtcout:RTC_TRACE("get_sdo_service(%s)", _id)
		self._sdoSvcProfiles = self._SdoConfigImpl:getServiceProfiles()
	
		if _id == "" then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="get_service(): Empty name."
			})
		end
	
		local index = CORBA_SeqUtil.find(self._sdoSvcProfiles, svc_name(_id))
	
		if index < 0 then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="get_service(): Not found"
			})
		end
		
	
		return self._sdoSvcProfiles[index].service
	end

	obj:setInstanceName(uuid())

	return obj
end




return RTObject
