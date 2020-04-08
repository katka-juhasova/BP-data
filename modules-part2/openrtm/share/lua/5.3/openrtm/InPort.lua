---------------------------------
--! @file InPort.lua
--! @brief インポートオブジェクト定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local InPort= {}
--_G["openrtm.InPort"] = InPort


local InPortBase = require "openrtm.InPortBase"
local DataPortStatus = require "openrtm.DataPortStatus"


-- InPort初期化
-- @param name ポート名
-- @param value データ変数
-- @param data_type データ型
-- @param buffer バッファ
-- @param read_block 読み込み時ブロックの設定
-- @param write_block 書き込み時時ブロックの設定
-- @param read_timeout 読み込み時のタイムアウト
-- @param write_timeout 書き込み時のタイムアウト
-- @return InPort
InPort.new = function(name, value, data_type, buffer, read_block, write_block, read_timeout, write_timeout)
	if read_block == nil then
		read_block = false
	end
	if write_block == nil then
		write_block = false
	end
	if read_timeout == nil then
		read_timeout = 0
	end
	if write_timeout == nil then
		write_timeout = 0
	end
	
	local obj = {}
	
	--print(data_type)
	setmetatable(obj, {__index=InPortBase.new(name, data_type)})
	obj._name           = name
    obj._value          = value
    obj._OnRead         = nil
    obj._OnReadConvert  = nil

    

	-- ポート名取得
	-- ※プロファイルのポート名ではない
	-- @return ポート名
	function obj:name()
		return self._name
	end

	-- 新規データの存在確認
	-- true；存在する、false：存在しない
	function obj:isNew()
		self._rtcout:RTC_TRACE("isNew()")



		if #self._connectors == 0 then
			self._rtcout:RTC_DEBUG("no connectors")
			return false
		end

		local r = self._connectors[1]:getBuffer():readable()
		if r > 0 then
			self._rtcout:RTC_DEBUG("isNew() = True, readable data: "..r)
			return true
		end

		self._rtcout:RTC_DEBUG("isNew() = False, no readable data")
		return false
	end

	-- 新規データがないことを確認
	-- @return true：存在しない、false：存在する
	function obj:isEmpty()
		self._rtcout:RTC_TRACE("isEmpty()")
		if #self._connectors == 0 then
			self._rtcout:RTC_DEBUG("no connectors")
			return true
		end

		local r = self._connectors[1]:getBuffer():readable()
		if r == 0 then
			self._rtcout:RTC_DEBUG("isEmpty() = true, buffer is empty")
			return true
		end

		self._rtcout:RTC_DEBUG("isEmpty() = false, data exists in the buffer")
		return false
	end

	-- データ読み込み
	-- 変換関数を設定している場合は、変換後のデータを返す
	-- コネクタ数が0、もしくはデータ読み込みに失敗した場合は、保持している変数をそのまま返す
	-- @return データ
	function obj:read()
		self._rtcout:RTC_TRACE("DataType read()")

		if self._OnRead ~= nil then
			self._OnRead:call()
			self._rtcout:RTC_TRACE("OnRead called")
		end




		

		if #self._connectors == 0 then
			self._rtcout:RTC_DEBUG("no connectors")
			return self._value
		end


		local cdr = {_data=self._value}
		local ret = self._connectors[1]:read(cdr)


		if ret == DataPortStatus.PORT_OK then
			self._rtcout:RTC_DEBUG("data read succeeded")
			self._value = cdr._data

			if self._OnReadConvert ~= nil then
				self._value = self._OnReadConvert:call(self._value)
				self._rtcout:RTC_DEBUG("OnReadConvert called")
				return self._value
			end
			return self._value


		elseif ret == DataPortStatus.BUFFER_EMPTY then
			self._rtcout:RTC_WARN("buffer empty")
			return self._value

		elseif ret == DataPortStatus.BUFFER_TIMEOUT then
			self._rtcout:RTC_WARN("buffer read timeout")
			return self._value
		end

		self._rtcout:RTC_ERROR("unknown retern value from buffer.read()")
		return self._value
	end
	-- 変数に最新値格納
	function obj:update()
		self:read()
	end
	-- データ読み込み時コールバックの設定
	-- @param on_read データ読み込み時コールバック
	function obj:setOnRead(on_read)
		self._OnRead = on_read
	end
	-- データ変換関数設定
	-- @param on_rconvert データ変換関数
	-- out_value = on_rconvert(in_value)という関数を指定
	function obj:setOnReadConvert(on_rconvert)
		self._OnReadConvert = on_rconvert
	end



	return obj
end


return InPort
