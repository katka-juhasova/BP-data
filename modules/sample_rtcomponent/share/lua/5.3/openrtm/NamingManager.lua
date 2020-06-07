---------------------------------
--! @file NamingManager.lua
--! @brief ネーミングマネージャ、名前管理基底クラスの定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local NamingManager= {}
--_G["openrtm.NamingManager"] = NamingManager

local oil = require "oil"
local CorbaNaming = require "openrtm.CorbaNaming"
local StringUtil = require "openrtm.StringUtil"
local RTCUtil = require "openrtm.RTCUtil"
local NVUtil = require "openrtm.NVUtil"
local CorbaConsumer = require "openrtm.CorbaConsumer"


NamingManager.NamingBase = {}

-- 名前管理基底オブジェクト初期化
-- @return 名前管理オブジェクト
NamingManager.NamingBase.new = function()
	local obj = {}
	-- RTCをネームサーバーに登録
	-- @param name 登録名
	-- @param rtobj RTC
	function obj:bindObject(name, rtobj)
	end
	-- ポートをネームサーバーに登録
	-- @param name 登録名
	-- @param port ポート
	function obj:bindPortObject(name, port)
	end
	-- オブジェクトをネームサーバーから登録解除
	-- @param name 登録名
	function obj:unbindObject(name)
	end
	-- ネームサーバー生存確認
	-- @return true：生存、false：終了済み
	function obj:isAlive()
		return true
	end
	-- 文字列からオブジェクトを取得
	-- @param name オブジェクト名
	-- @return オブジェクト一覧
	function obj:string_to_component(name)
		return {}
	end


	return obj
end

NamingManager.NamingOnCorba = {}

-- CORBAネームサーバー管理オブジェクト初期化
-- @param orb ORB
-- @param names アドレス
-- @return CORBAネームサーバー管理オブジェクト
NamingManager.NamingOnCorba.new = function(orb, names)
	local obj = {}
	setmetatable(obj, {__index=NamingManager.NamingBase.new()})
	local Manager = require "openrtm.Manager"
	obj._rtcout = Manager:instance():getLogbuf("manager.namingoncorba")
	obj._cosnaming = CorbaNaming.new(orb,names)
	obj._endpoint = ""
    obj._replaceEndpoint = false

	-- RTCをネームサーバーに登録
	-- @param name 登録名
	-- @param rtobj RTC
	function obj:bindObject(name, rtobj)

		self._rtcout:RTC_TRACE("bindObject(name = "..name..", rtobj or mgr)")
		local success, exception = oil.pcall(
			function()

				self._cosnaming:rebindByString(name, rtobj:getObjRef(), true)

			end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR(exception)
		end

    end

	-- オブジェクトをネームサーバーから登録解除
	-- @param name 登録名
	function obj:unbindObject(name)
		self._rtcout:RTC_TRACE("unbindObject(name  = "..name..")")
		local success, exception = oil.pcall(
			function()
				self._cosnaming:unbind(name)
			end)
		if not success then
			--print(exception)
			self._rtcout.RTC_ERROR(exception)
		end

	end


	-- ネームサーバーから指定名のRTCを検索
	-- @param context ネーミングコンテキスト
	-- @param name RTCの登録名
	-- @param rtcs 一致したRTC一覧
	function obj:getComponentByName(context, name, rtcs)

		local orb = Manager:instance():getORB()
		local BindingType = orb.types:lookup("::CosNaming::BindingType").labelvalue

		local length = 500

		local bl,bi = context:list(length)



		for k,i in ipairs(bl) do
			--print(i.binding_type, BindingType.ncontext)
			--print(NVUtil.getBindingType(i.binding_type), BindingType.ncontext)
			--print(i.binding_name)
			if NVUtil.getBindingType(i.binding_type) == BindingType.ncontext then
				local next_context = RTCUtil.newproxy(orb, context:resolve(i.binding_name),"IDL:omg.org/CosNaming/NamingContext:1.0")
				--print(next_context)
				self:getComponentByName(next_context, name, rtcs)
			elseif NVUtil.getBindingType(i.binding_type) == BindingType.nobject then
				if i.binding_name[1].id == name and i.binding_name[1].kind == "rtc" then
					--print(i.binding_name[1].id, i.binding_name[1].kind)
					local success, exception = oil.pcall(
						function()
							local cc = CorbaConsumer.new()
							cc:setObject(context:resolve(i.binding_name))
							local _obj = RTCUtil.newproxy(orb, cc:getObject(),"IDL:openrtm.aist.go.jp/OpenRTM/DataFlowComponent:1.0")

							if not NVUtil._non_existent(_obj) then
								table.insert(rtcs, _obj)
							end
					end)
					if not success then
						self._rtcout:RTC_ERROR(exception)
					end
				end
			end
		end
	end


	-- rtcname形式の文字列からRTCを取得
	-- @param name RTC名(rtcname形式)
	-- rtcname://localhost/test.host_cxt/ConsoleIn0
	-- @return 一致したRTC一覧
	function obj:string_to_component(name)

		local rtc_list = {}
		local tmp = StringUtil.split(name, "://")
		if #tmp > 1 then
			--print(tmp[1])
			if tmp[1] == "rtcname" then
				local url = tmp[2]
				local r = StringUtil.split(url, "/")

				if #r > 1 then
					local host = r[1]
					local rtc_name = string.sub(url, #host+2)
					--print(rtc_name)


					local success, exception = oil.pcall(
						function()

							local cns = nil
							if host == "*" then
								cns = self._cosnaming
							else
								local orb = Manager:instance():getORB()
								cns = CorbaNaming.new(orb,host)

							end

							local names = StringUtil.split(rtc_name, "/")


							if #names == 2 and names[1] == "*" then

								local root_cxt = cns:getRootContext()

								self:getComponentByName(root_cxt, names[2], rtc_list)
								return rtc_list
							else
								rtc_name = rtc_name..".rtc"

								local _obj = cns:resolveStr(rtc_name)

								if _obj == oil.corba.idl.null then
									return {}
								end
								if NVUtil._non_existent(_obj) then
									return {}
								end

								_obj = RTCUtil.newproxy(orb, _obj,"IDL:openrtm.aist.go.jp/OpenRTM/DataFlowComponent:1.0")


								table.insert(rtc_list, _obj)
								return rtc_list
							end
					end)
					if not success then
						return {}
					end
				end
			end
		end

		return rtc_list
	end


	return obj
end



NamingManager.NamingOnManager = {}

-- Manager名前管理オブジェクト初期化
-- @param orb ORB
-- @param mgr マネージャ
-- @return Manager名前管理オブジェクト
NamingManager.NamingOnManager.new = function(orb, mgr)
	local obj = {}
	setmetatable(obj, {__index=NamingManager.NamingBase.new()})
	local Manager = require "openrtm.Manager"
	obj._rtcout = Manager:instance():getLogbuf("manager.namingonmanager")
	obj._cosnaming = nil
	obj._orb = orb
	obj._mgr = mgr


	-- 指定ホスト名のマネージャを取得
	-- @param name ホスト名(例：localhost:2810)
	-- @return マネージャ
	function obj:getManager(name)
		if name == "*" then
			local mgr_sev = self._mgr:getManagerServant()
			local mgr = nil
			if mgr_sev:is_master() then
				mgr = mgr_sev:getObjRef()
			else
				local masters = mgr_sev:get_master_managers()
				if #masters > 0 then
					mgr = masters[1]
				else
					mgr = mgr_sev:getObjRef()
				end
			end
			return mgr
		end
		local success, exception = oil.pcall(
			function()
				local mgrloc = "corbaloc:iiop:"
				local prop = self._mgr:getConfig()
				local manager_name = prop:getProperty("manager.name")
				mgrloc = mgrloc..name
				mgrloc = mgrloc.."/"..manager_name




				mgr = RTCUtil.newproxy(self._orb, mgrloc,"IDL:RTM/Manager:1.0")
				--mgr = RTCUtil.newproxy(self._orb, mgrloc,"IDL:openrtm.aist.go.jp/OpenRTM/DataFlowComponent:1.0")

				--print(mgrloc)


				self._rtcout:RTC_DEBUG("corbaloc: "..mgrloc)
				--print(mgr)

		end)
		if not success then
			self._rtcout:RTC_DEBUG(exception)
		else
			return mgr
		end
		return oil.corba.idl.null
	end



	-- rtcloc形式の文字列からRTCを取得
	-- @param name RTC名(rtcloc形式)
	-- rtcloc://localhost:2010/Category/ConsoleIn0
	-- @return 一致したRTC一覧
	function obj:string_to_component(name)
		--print(name)
		local rtc_list = {}
		local tmp = StringUtil.split(name, "://")
		--print(#tmp)

		if #tmp > 1 then

			if tmp[1] == "rtcloc" then

				local url = tmp[2]
				local r = StringUtil.split(url, "/")
				if #r > 1 then
					local host = r[1]
					local rtc_name = string.sub(url, #host+2)


					local mgr = self:getManager(host)

					if mgr ~= oil.corba.idl.null then
						--print("test1")
						--print(mgr:get_master_managers())
						rtc_list = mgr:get_components_by_name(rtc_name)
						--print("test2")

						local slaves = mgr:get_slave_managers()

						for k,slave in ipairs(slaves) do
							local success, exception = oil.pcall(
								function()
									rtc_list.extend(slave:get_components_by_name(rtc_name))
							end)
							if not success then
								self._rtcout:RTC_DEBUG(exception)
								mgr:remove_slave_manager(slave)
							end
						end
					end
				end
				return rtc_list
			end
		end
		return rtc_list
	end

	return obj
end

-- 名前管理オブジェクト格納オブジェクト初期化
-- @param meth メソッド名
-- @param name オブジェクト名
-- @param naming 名前管理オブジェクト
-- @return 名前管理オブジェクト格納オブジェクト
NamingManager.NameServer = {}
NamingManager.NameServer.new = function(meth, name, naming)
	local obj = {}
	obj.method = meth
	obj.nsname = name
	obj.ns     = naming
	return obj
end


NamingManager.Comps = {}
-- RTC格納オブジェクト初期化
-- @param n 名前
-- @param _obj RTC
-- @return RTC格納オブジェクト
NamingManager.Comps.new = function(n, _obj)
	local obj = {}
	obj.name = n
	obj.rtobj = _obj
	return obj
end


NamingManager.Mgr = {}
NamingManager.Mgr.new = function(n, _obj)
	local obj = {}
	obj.name = n
	obj.mgr = _obj
	return obj
end

NamingManager.Port = {}
NamingManager.Port.new = function(n, _obj)
	local obj = {}
	obj.name = n
	obj.port = _obj
	return obj
end

-- ネーミングマネージャ初期化
-- @param manager マネージャ
-- @return ネーミングマネージャ
NamingManager.new = function(manager)
	local obj = {}
	obj._manager = manager
    obj._rtcout = manager:getLogbuf('manager.namingmanager')
    obj._names = {}
    obj._compNames = {}
    obj._mgrNames  = {}
    obj._portNames = {}
    -- 名前管理オブジェクト登録
    -- @param method メソッド名
    -- @param name_server アドレス
	function obj:registerNameServer(method, name_server)
		--print(self._rtcout)
		self._rtcout:RTC_TRACE("NamingManager::registerNameServer("..method..", "..name_server..")")
		local name = self:createNamingObj(method, name_server)
		--print(name)
		table.insert(self._names, NamingManager.NameServer.new(method, name_server, name))
	end
    -- 名前管理オブジェクト生成
    -- @param method メソッド名
    -- @param name_server アドレス
    -- @return 名前管理オブジェクト
	function obj:createNamingObj(method, name_server)
		--print(method)
		self._rtcout:RTC_TRACE("createNamingObj(method = "..method..", nameserver = "..name_server..")")

		local mth = method


		if mth == "corba" then
			local ret = nil
			local success, exception = oil.pcall(
				function()
					local name = NamingManager.NamingOnCorba.new(self._manager:getORB(),name_server)

					self._rtcout:RTC_INFO("NameServer connection succeeded: "..method.."/"..name_server)
					ret = name
				end)
			if not success then
				print(exception)
				self._rtcout:RTC_INFO("NameServer connection failed: "..method.."/"..name_server)
			end
			return ret
		elseif mth == "manager" then

			local name = NamingManager.NamingOnManager.new(self._manager:getORB(), self._manager)
			--print(name)
			return name
		end
		return nil
	end
	-- RTCをネームサーバーに登録
	-- @param name 登録名
	-- @param rtobj RTC
	function obj:bindObject(name, rtobj)
		self._rtcout:RTC_TRACE("NamingManager::bindObject("..name..")")
		for i, n in ipairs(self._names) do
			if n.ns ~= nil then
				local success, exception = oil.pcall(
					function()
						n.ns:bindObject(name, rtobj)
					end)
				if not success then
					n.ns = nil
				end
			end
		end

		self:registerCompName(name, rtobj)
	end
	function obj:bindManagerObject(name,  mgr)
		self._rtcout:RTC_TRACE("NamingManager::bindManagerObject("..name..")")
		for i, n in ipairs(self._names) do
			if n.ns ~= nil then
				local success, exception = oil.pcall(
					function()
						n.ns:bindObject(name, mgr)
					end)
				if not success then
					n.ns = nil
				end
			end
		end

		self:registerMgrName(name, mgr)
	end
	function obj:bindPortObject(name, port)
		self._rtcout:RTC_TRACE("NamingManager::bindPortObject("..name..")")
		for i, n in ipairs(self._names) do
			if n.ns ~= nil then
				local success, exception = oil.pcall(
					function()
						n.ns:bindObject(name, port)
					end)
				if not success then
					n.ns = nil
				end
			end
		end

		self:registerPortName(name, port)
	end
	-- RTCの登録
	-- @param name 登録名
	-- @param rtobj RTC
	function obj:registerCompName(name, rtobj)
		for i, compName in ipairs(self._compNames) do
			if compName.name == name then
				compName.rtobj = rtobj
				return
			end
		end
		table.insert(self._compNames, NamingManager.Comps.new(name, rtobj))
	end

	function obj:registerMgrName(name, mgr)
		for i, mgrName in ipairs(self._mgrNames) do
			if mgrName.name == name then
				mgrName.mgr = mgr
				return
			end
		end
		table.insert(self._mgrNames, NamingManager.Mgr.new(name, rtobj))
	end

	function obj:registerPortName(name, port)
		for i, portName in ipairs(self._portNames) do
			if portName.name == name then
				portName.port = port
				return
			end
		end
		table.insert(self._portNames, NamingManager.Port.new(name, port))
    end

	-- RTCをネームサーバーから登録解除
	-- @param name 登録名
	function obj:unbindObject(name)
		self._rtcout:RTC_TRACE("NamingManager::unbindObject("..name..")")
		for i,n in ipairs(self._names) do
			if n.ns ~= nil then
				n.ns:unbindObject(name)
			end
		end
		self:unregisterCompName(name)
		self:unregisterMgrName(name)
		self:unregisterPortName(name)
	end

	function obj:unbindAll()
		self._rtcout:RTC_TRACE("NamingManager::unbindAll(): %d names.", #self._compNames)
		for i, compName in ipairs(self._compNames) do
			self:unbindObject(compName.name)
		end
		for i, mgrName in ipairs(self._mgrNames) do
			self:unbindObject(mgrName.name)
		end
		for i, portName in ipairs(self._portNames) do
			self:unbindObject(portName.name)
		end
	end

	-- RTCの登録解除
	-- @param name 登録名
	function obj:unregisterCompName(name)
		for i, compName in ipairs(self._compNames) do
			if compName.name == name then
				table.remove(self._compNames, i)
				return
			end
		end
	end
	-- マネージャの登録解除
	-- @param name 登録名
	function obj:unregisterMgrName(name)
		for i, mgrName in ipairs(self._mgrNames) do
			if mgrName.name == name then
				table.remove(self._mgrNames, i)
				return
			end
		end
	end
	-- ポートの登録解除
	-- @param name 登録名
	function obj:unregisterPortName(name)
		for i, portName in ipairs(self._portNames) do
			if portName.name == name then
				table.remove(self._portNames, i)
				return
			end
		end
	end

	-- rtcloc、rtcname形式の文字列からRTCを取得
	-- @param name RTC名
	-- @return 一致したRTC一覧
	function obj:string_to_component(name)
		for k,n in ipairs(self._names) do
			if n.ns ~= nil then
				local comps = n.ns:string_to_component(name)
				if #comps > 0 then
					return comps
				end
			end
		end
		return {}
	end

	function obj:getObjects()
		local comps = {}
		for k,comp in ipairs(self._compNames) do
			table.insert(comps, comp.rtobj)
		end
		return comps
	end

	return obj
end



return NamingManager
