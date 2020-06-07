---------------------------------
--! @file CorbaConsumer.lua
--! @brief CORBAコンシューマ定義クラス
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local CorbaConsumer= {}
--_G["openrtm.CorbaConsumer"] = CorbaConsumer


local oil = require "oil"
local RTCUtil = require "openrtm.RTCUtil"


CorbaConsumer.CorbaConsumerBase = {}

-- CORBAコンシューマオブジェクト初期化関数
-- @param consumer CORBAコンシューマオブジェクト
-- @return CORBAコンシューマオブジェクト
CorbaConsumer.CorbaConsumerBase.new = function(consumer)
	local obj = {}

	if consumer ~= nil then
		obj._objref = consumer._objref
	else
		obj._objref = oil.corba.idl.null
	end
	
	-- オブジェクトリファレンス設定
	-- @param _obj オブジェクトリファレンス
	-- @return true：設定成功、false：設定失敗
	function obj:setObject(_obj)
		return self:_setObject(_obj)
	end
	-- オブジェクトリファレンス設定
	-- @param _obj オブジェクトリファレンス
	-- @return true：設定成功、false：設定失敗
	function obj:_setObject(_obj)

		if _obj == nil then
			return false
		end

		self._objref = _obj
		
		return true
	end

	-- オブジェクトリファレンス取得
	-- @return オブジェクトリファレンス
	function obj:getObject()
		--print(self._objref)
		return self._objref
	end

	-- オブジェクトリファレンスをnullに設定する
	function obj:releaseObject()
		self:_releaseObject()
	end
	-- オブジェクトリファレンスをnullに設定する
	function obj:_releaseObject()
		self._objref = oil.corba.idl.null
	end

	return obj
end

-- CORBAコンシューマオブジェクト初期化関数
-- @param interfaceType インターフェース型
-- @param consumer CORBAコンシューマオブジェクト
-- @return CORBAコンシューマオブジェクト
CorbaConsumer.new = function(interfaceType, consumer)
	local obj = {}
	obj._interfaceType = interfaceType
	setmetatable(obj, {__index=CorbaConsumer.CorbaConsumerBase.new(consumer)})
	if consumer ~= nil then
		obj._var = consumer._var
	end
	-- オブジェクトリファレンス設定
	-- @param _obj オブジェクトリファレンス
	-- @return true：設定成功、false：設定失敗
	function obj:setObject(_obj)

		if not self:_setObject(_obj) then
			self:releaseObject()
			return false
		end

		self._var = self._objref
		return true
	end
	-- オブジェクトリファレンス取得
	-- 同一プロセスの場合はサーバント取得
	-- @param get_ref trueの場合にはサーバント取得可能でもオブジェクトリファレンスを取得
	-- @return オブジェクトリファレンス、もしくはサーバント
	function obj:_ptr(get_ref)
		if get_ref == nil then
			get_ref = false
		end
		return self._var
	end
	-- IOR文字列からオブジェクトリファレンスを設定
	-- 設定したインターフェース型に変換する
	-- @param ior IOR文字列
	-- @return true：設定成功、false：設定失敗
	function obj:setIOR(ior)
		local ret = true
		local success, exception = oil.pcall(
			function()
				--print(ior)
				--print(self._interfaceType)
				local Manager = require "openrtm.Manager"
				local orb = Manager:instance():getORB()
				local obj_ = RTCUtil.newproxy(orb, ior,self._interfaceType)
				if not self:_setObject(obj_) then
					self:releaseObject()
					ret = false
				end
				self._var = self._objref
			end)
		if not success then
			print(exception)
			return false
		end


		return ret
	end

	-- オブジェクトリファレンスにnullを設定する
	function obj:releaseObject()
		self:_releaseObject(self)
		self._var = oil.corba.idl.null
		self._sev = nil
	end
	return obj
end


return CorbaConsumer
