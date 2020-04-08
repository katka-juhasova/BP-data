---------------------------------
--! @file PortAdmin.lua
--! @brief ポート管理クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PortAdmin= {}
--_G["openrtm.PortAdmin"] = PortAdmin


local oil = require "oil"
local ObjectManager = require "openrtm.ObjectManager"
local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"


-- ポートの名前が一致しているか判定する関数オブジェクト初期化
-- @param argv argv.name：型名、argv.factory：ファクトリ
-- @return 関数オブジェクト
local comp_op = function(argv)
	local obj = {}
	if argv.name ~= nil then
		obj._name = argv.name
	elseif argv.factory ~= nil then
		obj._name = argv.factory:getProfile().name
	end
	-- ポートの名前が一致しているか判定する
	-- @param self 自身のオブジェクト
	-- @param obj RTC
	-- @return true：一致、false：不一致 
	local call_func = function(self, obj)
		name_ = obj:getProfile().name
		return (self._name == name_)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


local find_port_name = {}
-- ポート名が一致しているか判定する関数オブジェクト初期化
-- @param name ポート名
-- @return 関数オブジェクト
find_port_name.new = function(name)
	local obj = {}
	obj._name = name
	--ポート名が一致しているか判定する
	-- @param self 自身のオブジェクト
	-- @param p ポート
	-- @return true：一致、false：不一致
	local call_func = function(self, p)
		local prof = p:get_port_profile()
		local name_ = prof.name
		--print(self._name, name_)
		return (self._name == name_)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

-- ポート管理オブジェクト初期化
-- @param orb ORB
-- @return ポート管理オブジェクト
PortAdmin.new = function(orb)
	local obj = {}
	obj._orb = orb
	obj._portRefs = {}
	obj._portServants = ObjectManager.new(comp_op)
	local Manager = require "openrtm.Manager"
	obj._rtcout = Manager:instance():getLogbuf("PortAdmin")

	-- ポートのインターフェースのアクティブ化
	function obj:activatePorts()
		--print("activatePorts1")
		local ports = self._portServants:getObjects()
		for i, port in pairs(ports) do
			port:activateInterfaces()
		end
		--print("activatePorts2")
    end
    -- ポートのインターフェースの非アクティブ化
	function obj:deactivatePorts()
		ports = self._portServants:getObjects()
		for i, port in pairs(ports) do
			port:deactivateInterfaces()
		end
    end
    -- ポートのプロファイル一覧取得
    -- @return プロファイル一覧
	function obj:getPortProfileList()
		local ret = {}
		for i, p in ipairs(self._portRefs) do
			table.insert(ret, p:get_port_profile())
		end
		return ret
	end

	-- ポート追加
	-- @param port ポート
	-- @return true：登録成功、false：登録失敗
	function obj:addPort(port)
		local index = CORBA_SeqUtil.find(self._portRefs,
									find_port_name.new(port:getName()))
		if index >= 0 then
			return false
		end
		--print(port:getPortRef())
		table.insert(self._portRefs, port:getPortRef())
		return self._portServants:registerObject(port)
	end

	-- ポート削除
	-- @param port ポート
	-- @return true：削除成功、false：削除失敗
	function obj:removePort(port)
		local ret = false
		local success, exception = oil.pcall(
			function()

			port:disconnect_all()
			tmp = port:getProfile().name
			--print(#self._portRefs)
			CORBA_SeqUtil.erase_if(self._portRefs, find_port_name.new(tmp))
			--print(#self._portRefs)
			port:deactivate()


			port:setPortRef(oil.corba.idl.null)

			if not self._portServants:unregisterObject(tmp) then
				ret = false
				return
			end
			ret = true
			end)
		if not success then
			--print(exception)
			self._rtcout:RTC_ERROR(exception)
			return false
		end
		return ret
	end

	-- ポートのオブジェクトリファレンス一覧取得
	-- @return ポートのオブジェクトリファレンス一覧
	function obj:getPortServiceList()
		return self._portRefs
	end

	-- 全ポート削除
	function obj:finalizePorts()
		self:deactivatePorts()
		local ports = self._portServants:getObjects()
		for i, port in ipairs(ports) do
			self:removePort(port)
		end
	end

	return obj
end


return PortAdmin
