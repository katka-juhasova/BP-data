---------------------------------
--! @file RTCUtil.lua
--! @brief RTCヘルパ関数
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local RTCUtil= {}
--_G["openrtm.RTCUtil"] = RTCUtil


local oil = require "oil"

-- オブジェクトのプロキシサーバント生成
-- @param orb ORB
-- @param ior IOR文字列
-- @param idl IDLファイル
-- @return サーバント
RTCUtil.newproxy = function(orb, ior, idl)
	if type(ior) == "table" then
		if ior.getObjRef ~= nil then
			return ior:getObjRef()
		end
	end
	if oil.VERSION == "OiL 0.4 beta" then
		if type(ior) == "table" then
			ior = orb:tostring(ior)
		end
		return orb:newproxy(ior,idl)
	elseif oil.VERSION == "OiL 0.5" or oil.VERSION == "OiL 0.6" then
		return orb:newproxy(ior,nil,idl)
	end
	return nil
end

-- オブジェクトリファレンス取得
-- @param orb ORB
-- @param servant サーバント
-- @param idl IDLファイル
-- @return オブジェクトリファレンス
RTCUtil.getReference = function(orb, servant, idl)
	if oil.VERSION == "OiL 0.4 beta" then
		local ior = orb:tostring(servant)
		return RTCUtil.newproxy(orb, ior, idl)
	elseif oil.VERSION == "OiL 0.5" or oil.VERSION == "OiL 0.6" then
		return servant
	end
	return nil
end

-- データのインスタンスをデータ型から取得
-- @param data_type データ型(文字列)
-- @return データのインスタンス
RTCUtil.instantiateDataType = function(data_type)
	local Manager = require "openrtm.Manager"
	local orb = Manager:getORB()
	local data = orb.types:lookup(data_type)
	local ret = {}
	for k,v in pairs(data.fields) do
		RTCUtil.getDataType(v, ret)
	end
	return ret
	--return {tm={sec=0,nsec=0},data={}}
end

-- データの要素を抽出する
-- @param data データ
-- @param ret データのインスタンス
RTCUtil.getDataType = function(data, ret)
	if data.type_def ~= nil then
		--print(data.type_def._type)
		if data.type_def._type == "struct" then
			ret[data.name] = {}
		elseif data.type_def._type == "ulong" then
			ret[data.name] = 0
			return
		elseif data.type_def._type == "long" then
			ret[data.name] = 0
			return
		elseif data.type_def._type == "short" then
			ret[data.name] = 0
			return
		elseif data.type_def._type == "ushort" then
			ret[data.name] = 0
			return
		elseif data.type_def._type == "octet" then
			ret[data.name] = 0x00
			return
		elseif data.type_def._type == "string" then
			ret[data.name] = ""
			return
		elseif data.type_def._type == "float" then
			ret[data.name] = 0
			return
		elseif data.type_def._type == "double" then
			ret[data.name] = 0
			return
		--[[
		elseif data.type_def._type == "ufloat" then
			ret[data.name] = 0
			return
		elseif data.type_def._type == "udouble" then
			ret[data.name] = 0
			return
		--]]
		elseif data.type_def._type == "char" then
			ret[data.name] = ""
			return
		elseif data.type_def._type == "boolean" then
			ret[data.name] = true
			return
		elseif data.type_def._type == "sequence" then
			ret[data.name] = {}
			return
		else
			ret[data.name] = 0
			return
		end
		for k,v in pairs(data.type_def.fields) do
			RTCUtil.getDataType(v, ret[data.name])
		end
	end
end


return RTCUtil
