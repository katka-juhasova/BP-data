---------------------------------
--! @file CorbaNaming.lua
--! @brief ネームサーバーヘルパクラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local CorbaNaming= {}
--_G["openrtm.CorbaNaming"] = CorbaNaming

local oil = require "oil"
local StringUtil = require "openrtm.StringUtil"
local RTCUtil = require "openrtm.RTCUtil"


-- ネームサーバーヘルパオブジェクト初期化
-- @param orb ORBオブジェクト
-- @param name_server ネームサーバーのアドレス(例：localhost:2809)
-- @return ネームサーバヘルパオブジェクト
CorbaNaming.new = function(orb, name_server)
	local obj = {}
	obj._orb = orb
    obj._nameServer = ""
    obj._rootContext = oil.corba.idl.null
    obj._blLength = 100

	if name_server ~= nil then
		obj._nameServer = "corbaloc:iiop:"..name_server.."/NameService"
		--print(obj._nameServer)
		local success, exception = oil.pcall(
			function()
				obj._rootContext = RTCUtil.newproxy(obj._orb, obj._nameServer,"IDL:omg.org/CosNaming/NamingContext:1.0")
				--print(self._rootContext)
				--if self._rootContext == nil then
				--	print("CorbaNaming: Failed to narrow the root naming context.")
				--end
			end)
		if not success then
			print(exception)
		end
	end
	-- ネームサーバーにオブジェクトを登録
	-- 登録パスは以下のように設定する
	-- test1.host_cxt/test2.rtc
	-- @param string_name 登録パス(文字列)
	-- @param obj オブジェクトリファレンス
	-- @param force trueの場合には同じパスに登録済みの場合でも強制的に上書きする
	function obj:rebindByString(string_name, obj, force)
		if force == nil then
			force = true
		end
		--print(self:toName(string_name))
		self:rebind(self:toName(string_name), obj, force)
	end
	-- ネームサーバーにオブジェクトを登録
	-- Nameリストは以下のように指定
	-- {{id="id1",kind="kind1"},...}
	-- @param name_list 登録パス(Nameリスト)
	-- @param obj オブジェクトリファレンス
	-- @param force trueの場合には同じパスに登録済みの場合でも強制的に上書きする
	function obj:rebind(name_list, obj, force)
		if force == nil then
			force = true
		end
		local success, exception = oil.pcall(
			function()
				--error("")
				self._rootContext:rebind(name_list, obj)
			end)
		if not success then
			--print(exception)
			if force then
				--print("test1")
				self:rebindRecursive(self._rootContext, name_list, obj)
				--print("test2")
			else
				print(exception)
				error(exception)
			end
		end
	end
	-- ネームサーバーにオブジェクトを登録する
	-- 指定パスのコンテキストがない場合は生成する
	-- Nameリストは以下のように指定
	-- {{id="id1",kind="kind1"},...}
	-- @param context ルートコンテキスト
	-- @param name_list 登録パス(Nameリスト)
	-- @param 登録オブジェクト
	function obj:rebindRecursive(context, name_list, _obj)
		local length = #name_list
		for i =1,length do
			if i == length then
				--print("test1")
				context:rebind(self:subName(name_list, i, i), _obj)
				--print("test2")
				return
			else
				if self:objIsNamingContext(context) then
					local success, exception = oil.pcall(
						function()
							context = context:bind_new_context(self:subName(name_list, i, i))
						end)
					if not success then
						--print(exception)
						context = context:resolve(self:subName(name_list, i, i))
					end
				else
					error("CosNaming.NamingContext.CannotProceed")
				end
			end
		end
	end
	-- オブジェクトがコンテキストかを判定
	-- 未実装
	-- @return true：オブジェクトはコンテキスト、false：それ以外
	function obj:objIsNamingContext(obj)
		return true
	end

	-- 文字列をNameリストに変換
	-- 文字列で以下のように設定する
	-- test1.host_cxt/test2.rtc
	-- @param 設定パス(文字列)
	-- @return 設定パス(Nameリスト)
	-- 戻り値は以下のようになる
	-- {{id="test1",kind="host_cxt"},{id="test2",kind="rtc"}}
	function obj:toName(sname)
		if sname == "" then
			error("CosNaming.NamingContext.InvalidName")
		end
		local string_name = sname
		local name_comps = {}
		--print(string_name)
		name_comps = StringUtil.split(string_name,"/")
		local name_list = {}
		for i, comp in ipairs(name_comps) do
			local s = StringUtil.split(comp,"%.")
			name_list[i] = {}
			if #s == 1 then
				name_list[i].id = comp
				name_list[i].kind = ""
			else
				local n = ""
				for i=1,#s-1 do
					n = n..s[i]
					if i ~= #s-1 then
						n = n.."."
					end
				end
				name_list[i].id = n
				name_list[i].kind = s[#s]
			end
		end
		return name_list
	end
	-- Nameリストから、指定したインデックス間の要素を抽出する
	-- Nameリストは以下のように指定
	-- {{id="id1",kind="kind1"},...}
	-- @param Nameリスト
	-- @param begin 開始インデックス
	-- @param _end 終了インデックス
	-- @return 抽出したリスト
	function obj:subName(name_list, begin, _end)
		if _end == nil  or _end < 1 then
			_end = #name_list
		end
		sub_name = {}
		for i =begin,_end do
			table.insert(sub_name, name_list[i])
		end
		return sub_name

	end

	-- ネームサーバーから指定パスのオブジェクトを削除
	-- Nameリストは以下のように指定
	-- {{id="id1",kind="kind1"},...}
	-- @param name 削除パス(Nameオブジェクト)
	function obj:unbind(name)
		local name_ = name
		if type(name) == "string" then
			name_ = self:toName(name)
		end

		local success, exception = oil.pcall(
			function()
				self._rootContext:unbind(name_)
			end)
		if not success then
			print(exception)
		end
    end

	-- 名前からオブジェクトを取得
	-- @param name 名前リスト
	-- {{id="id1",kind="kind1"},...}
	-- @return オブジェクト
	function obj:resolve(name)
		local name_ = ""
		if type(name) == "string" then
			name_ = self:toName(name)
		else
			name_ = name
		end
		local _obj = oil.corba.idl.null
		local success, exception = oil.pcall(
			function()
			_obj = self._rootContext:resolve(name_)
		end)

		if not success then
			print(exception)
			return oil.corba.idl.null
		end
		if _obj ~= nil then
			return _obj
		end
	end

	-- 名前からオブジェクトを取得
	-- @param string_name 名前
	-- test1.host_cxt/test2.rtc
	-- @return オブジェクト
	function obj:resolveStr(string_name)
		return self:resolve(self:toName(string_name))
	end

	-- ルートコンテキスト取得
	-- @return ルートコンテキスト
	function obj:getRootContext()
		return self._rootContext
	end

	return obj
end


return CorbaNaming
