---------------------------------
--! @file NVUtil.lua
--! @brief NameValeヘルパ関数
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local NVUtil= {}
--_G["openrtm.NVUtil"] = NVUtil

local oil = require "oil"
local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"
local StringUtil = require "openrtm.StringUtil"

-- NameValue生成
-- @param name キー
-- @param value 値
-- @return NameValue
NVUtil.newNV = function(name, value)
	return {name=name, value=value}
end

-- プロパティからNameValueをコピーする
-- @param nv NameValue
-- @param prop プロパティ
NVUtil.copyFromProperties = function(nv, prop)
	local keys = prop:propertyNames()
	local keys_len = #keys
	local nv_len = #nv
	if nv_len > 0 then
		for i = 1,nv_len do
			nv[i] = nil
		end
	end

	for i = 1, keys_len do
		table.insert(nv, NVUtil.newNV(keys[i], prop:getProperty(keys[i])))
	end
end

-- 文字列をRTC::ReturnCode_tに変換
-- @param ret_code リターンコード(文字列)
-- @return リターンコード
NVUtil.getReturnCode = function(ret_code)
	--print(ret_code)
	if type(ret_code) == "string" then
		local Manager = require "openrtm.Manager"
		local _ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
		if ret_code == "RTC_OK" then
			return _ReturnCode_t.RTC_OK
		elseif ret_code == "RTC_ERROR" then
			return _ReturnCode_t.RTC_ERROR
		elseif ret_code == "BAD_PARAMETER" then
			return _ReturnCode_t.BAD_PARAMETER
		elseif ret_code == "UNSUPPORTED" then
			return _ReturnCode_t.UNSUPPORTED
		elseif ret_code == "OUT_OF_RESOURCES" then
			return _ReturnCode_t.OUT_OF_RESOURCES
		elseif ret_code == "PRECONDITION_NOT_MET" then
			return _ReturnCode_t.PRECONDITION_NOT_MET
		end
	end
	return ret_code
end

-- 文字列をOpenRTM::PortStatusに変換
-- @param ret_code ポートステータス(文字列)
-- @return ポートステータス
NVUtil.getPortStatus = function(ret_code)
	--print(ret_code)
	if type(ret_code) == "string" then
		local Manager = require "openrtm.Manager"
		local _PortStatus = Manager:instance():getORB().types:lookup("::OpenRTM::PortStatus").labelvalue

		if ret_code == "PORT_OK" then
			return _PortStatus.PORT_OK
		elseif ret_code == "PORT_ERROR" then
			return _PortStatus.PORT_ERROR
		elseif ret_code == "BUFFER_FULL" then
			return _PortStatus.BUFFER_FULL
		elseif ret_code == "BUFFER_EMPTY" then
			return _PortStatus.BUFFER_EMPTY
		elseif ret_code == "BUFFER_TIMEOUT" then
			return _PortStatus.BUFFER_TIMEOUT
		elseif ret_code == "UNKNOWN_ERROR" then
			return _PortStatus.UNKNOWN_ERROR
		end
	end
	return ret_code
end

-- 文字列をRTC::PortStatusに変換
-- @param ret_code ポートステータス(文字列)
-- @return ポートステータス
NVUtil.getPortStatus_RTC = function(ret_code)
	--print(ret_code)
	if type(ret_code) == "string" then
		local Manager = require "openrtm.Manager"
		local _PortStatus = Manager:instance():getORB().types:lookup("::RTC::PortStatus").labelvalue

		if ret_code == "PORT_OK" then
			return _PortStatus.PORT_OK
		elseif ret_code == "PORT_ERROR" then
			return _PortStatus.PORT_ERROR
		elseif ret_code == "BUFFER_FULL" then
			return _PortStatus.BUFFER_FULL
		elseif ret_code == "BUFFER_EMPTY" then
			return _PortStatus.BUFFER_EMPTY
		elseif ret_code == "BUFFER_TIMEOUT" then
			return _PortStatus.BUFFER_TIMEOUT
		elseif ret_code == "UNKNOWN_ERROR" then
			return _PortStatus.UNKNOWN_ERROR
		end
	end
	return ret_code
end


-- NameValueからプロパティにコピーする
-- @param prop プロパティ
-- @param nvlist NameValue
NVUtil.copyToProperties = function(prop, nvlist)
	for i, nv in ipairs(nvlist) do
		--print(i,nv.value)
		local val = NVUtil.any_from_any(nv.value)
		--print(val)
		prop:setProperty(nv.name,val)
	end
end

local nv_find = {}

-- NaveValueを検索するための関数オブジェクト初期化
-- return NaveValueを検索するための関数オブジェクト
nv_find.new = function(name)
	local obj = {}
	obj._name  = name
	-- NameValueが指定名と一致するかを判定
	-- @param self 自身のオブジェクト
	-- @param nv NameValue
	-- @return true：一致、false：不一致
	local call_func = function(self, nv)
		--print(self._name, nv.name)
		return (self._name == nv.name)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

-- 名前からNameValueを取得
-- @param nv NameValueのリスト
-- @param name 要素名
-- @return 一致したNamValueの配列番号
NVUtil.find_index = function(nv, name)
	return CORBA_SeqUtil.find(nv, nv_find.new(name))
end

-- NameValueのリストに指定名、値を追加
-- 既に指定名のNameValueが存在する場合は上書き
-- ","で区切る値の場合は後ろに追加
-- @param nv NameValueのリスト
-- @param _name 要素名
-- @param _value 値
NVUtil.appendStringValue = function(nv, _name, _value)
	local index = NVUtil.find_index(nv, _name)
	local tmp_nv = nv[index]
	if tmp_nv ~= nil then
		local tmp_str = NVUtil.any_from_any(tmp_nv.value)
		local values = StringUtil.split(tmp_str,",")
		local find_flag = false
		for i, val in ipairs(values) do
			if val == _value then
				find_flag = true
			end
		end
		if not find_flag then
			tmp_str = tmp_str..", "
			tmp_str = tmp_str.._value
			tmp_nv.value = tmp_str
		end
	else
		table.insert(nv,{name=_name,value=_value})
	end
end

-- NameValueのリストを連結する
-- @param dest 連結先のNameValueのリスト
-- @param src 連結元のNameValueのリスト
NVUtil.append = function(dest, src)
	for i, val in ipairs(src) do
		table.insert(dest, val)
	end
end


-- NameValueリストの指定名の値が指定文字列と一致するかを判定
-- @param nv NameValueリスト
-- @param name 要素名
-- @param value 値(文字列)
-- @return true：一致、false：不一致、指定要素がない
NVUtil.isStringValue = function(nv, name, value)
	--print(NVUtil.toString(nv, name))
	if NVUtil.isString(nv, name) then
		if NVUtil.toString(nv, name) == value then
			return true
		end
	end
	return false
end

-- NameValueリストから指定要素の値を取得
-- @param nv NameValueリスト
-- @param name 要素名
-- @return 指定要素
NVUtil.find = function(nv, name)
	local index = CORBA_SeqUtil.find(nv, nv_find.new(name))
	if nv[index] ~= nil then
		return nv[index].value
	else
		return nil
	end
end

-- オブジェクトリファレンスの一致を判定
-- @param obj1 オブジェクト1
-- @param obj2 オブジェクト2
-- @param obj1_ref オブジェクト1のリファレンス
-- @param obj2_ref オブジェクト2のリファレンス
-- @return true：一致、false：不一致
NVUtil._is_equivalent = function(obj1, obj2, obj1_ref, obj2_ref)
	if oil.VERSION == "OiL 0.4 beta" then
		if obj1._is_equivalent == nil then
			if obj2._is_equivalent == nil then
				return obj1_ref(obj1):_is_equivalent(obj2_ref(obj2))
			else
				return obj1_ref(obj1):_is_equivalent(obj2)
			end
		else
			if obj2._is_equivalent == nil then

				return obj1:_is_equivalent(obj2_ref(obj2))
			else
				return obj1:_is_equivalent(obj2)
			end
		end
	elseif oil.VERSION == "OiL 0.5" then
		if obj1._is_equivalent == nil then

			obj1 = obj1_ref(obj1)
		end
		if obj2._is_equivalent == nil then
			obj2 = obj2_ref(obj2)
		end
		--print(obj1,obj2,(obj1 == obj2))
		if obj1._is_equivalent == nil or obj2._is_equivalent == nil then
			return (obj1 == obj2)
		else
			return obj1:_is_equivalent(obj2)
		end
	elseif oil.VERSION == "OiL 0.6" then
		if obj1._is_equivalent == nil then

			obj1 = obj1_ref(obj1)
		end
		if obj2._is_equivalent == nil then
			obj2 = obj2_ref(obj2)
		end
		if obj1._is_equivalent == nil and obj2._is_equivalent == nil then
			return (obj1 == obj2)
		else
			if obj1._is_equivalent ~= nil then
				return obj1:_is_equivalent(obj2)
			else
				return obj2:_is_equivalent(obj1)
			end
		end
	end
end

-- 指定変数がanyの場合に値を取り出す
-- @param value 変数
-- @return 取り出した値
NVUtil.any_from_any = function(value)
	if type(value) == "table" then
		if value._anyval ~= nil then
			return value._anyval
		end
	end
	return value
end

-- NameValueリストを表示用文字列に変換
-- @param nv NameValueリスト
-- @return 文字列
NVUtil.dump_to_stream = function(nv)
	local out = ""
	for i, n in ipairs(nv) do
		local val = NVUtil.any_from_any(nv[i].value)
		if type(val) == "string" then
			out = out..n.name..": "..val.."\n"
		else
			out = out..n.name..": not a string value \n"
		end
	end
	return out
end

-- NameValueリストの指定要素を文字列に変換
-- @param nv NameValueリスト
-- @param name 要素名
-- @return 文字列
NVUtil.toString = function(nv, name)
	if name == nil then
		return NVUtil.dump_to_stream(nv)
	end

	local str_value = ""
    local ret_value = NVUtil.find(nv, name)
	if ret_value ~= nil then
		local val = NVUtil.any_from_any(ret_value)
		if type(val) == "string" then
			str_value = val
		end
	end
	return str_value
end

-- NameValueの指定要素が文字列かを判定
-- @param nv NameValueリスト
-- @param name 要素名
-- @return true：文字列、false：文字列以外
NVUtil.isString = function(nv, name)
    local value = NVUtil.find(nv, name)
	if value ~= nil then
		local val = NVUtil.any_from_any(value)
		return (type(val) == "string")
	else
		return false
	end
end


-- 文字列をCosNamingのBindingTypeに変換
-- @param binding_type バインディング型(文字列)
-- @return バインディング型
NVUtil.getBindingType = function(binding_type)
	if type(binding_type) == "string" then
		local Manager = require "openrtm.Manager"
		local _BindingType = Manager:instance():getORB().types:lookup("::CosNaming::BindingType").labelvalue

		if binding_type == "ncontext" then
			return _BindingType.ncontext
		elseif binding_type == "nobject" then
			return _BindingType.nobject
		end
	end
	return binding_type
end


-- 文字列をRTCの状態に変換
-- @param state RTCの状態(文字列)
-- @return RTCの状態
NVUtil.getLifeCycleState = function(state)
	--print(state)
	if type(state) == "string" then
		local Manager = require "openrtm.Manager"
		local _LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue
		if state == "CREATED_STATE" then
			return _LifeCycleState.CREATED_STATE
		elseif state == "INACTIVE_STATE" then
			return _LifeCycleState.INACTIVE_STATE
		elseif state == "ACTIVE_STATE" then
			return _LifeCycleState.ACTIVE_STATE
		elseif state == "ERROR_STATE" then
			return _LifeCycleState.ERROR_STATE
		end
	end
	return state
end

-- CORBAオブジェクトの生存確認
-- @param _obj CORBAオブジェクト
-- @return false：生存
NVUtil._non_existent = function(_obj)
	--print(_obj._non_existent)
	if _obj._non_existent == nil then
		return false
	else
		local ret = true
		local success, exception = oil.pcall(
			function()
				ret = _obj:_non_existent()
		end)
		return ret
	end
end


return NVUtil
