---------------------------------
--! @file RingBuffer.lua
--! @brief リングバッファ定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local RingBuffer= {}
--_G["openrtm.RingBuffer"] = RingBuffer


local BufferBase = require "openrtm.BufferBase"
local TimeValue = require "openrtm.TimeValue"
local BufferStatus = require "openrtm.BufferStatus"
local StringUtil = require "openrtm.StringUtil"


RingBuffer.RINGBUFFER_DEFAULT_LENGTH = 8

-- リングバッファ初期化
-- @param length バッファ長
-- @return リングバッファ
RingBuffer.new = function(length)
	local obj = {}
	setmetatable(obj, {__index=BufferBase.new()})
	if length == nil then
		length = RingBuffer.RINGBUFFER_DEFAULT_LENGTH
	end
	obj._overwrite = true
    obj._readback = true
    obj._timedwrite = false
    obj._timedread  = false
    obj._wtimeout = TimeValue.new(1,0)
    obj._rtimeout = TimeValue.new(1,0)
    obj._length   = length
    obj._wpos = 0
    obj._rpos = 0
    obj._fillcount = 0
    obj._wcount = 0
    obj._buffer = {}

	-- 初期化時にプロパティを設定
	-- @param prop プロパティ
	function obj:init(prop)
		self:__initLength(prop)
		self:__initWritePolicy(prop)
		self:__initReadPolicy(prop)
	end

	-- バッファ長設定、取得
	-- @param n バッファ長
	-- @return バッファステータス(nがnilの場合は長さ)
	-- BUFFER_OK：正常に設定完了、NOT_SUPPORTED：長さが不正
	function obj:length(n)
		if n == nil then
			return self._length
		end

		if n < 1 then
			return BufferStatus.NOT_SUPPORTED
		end

		self._buffer = {}
		self._length = n
		self:reset()
		return BufferStatus.BUFFER_OK
	end

	-- バッファポインタをリセット
	function obj:reset()
		self._fillcount = 0
		self._wcount = 0
		self._wpos = 0
		self._rpos = 0
	end

	-- 指定位置まで書き込みポインタを進めた場合のバッファ取得
	-- @param n ポインタの位置
	-- @return 現在の位置のバッファ
	function obj:wptr(n)
		if n == nil then
			n = 0
		end
		return self._buffer[(self._wpos + n + self._length) % self._length + 1]
	end

	-- 書き込みポインタの位置を進める
	-- @param n ポインタの位置
	-- @return バッファステータス
	-- BUFFER_OK：正常に位置設定完了、PRECONDITION_NOT_MET：移動不可
	function obj:advanceWptr(n)
		if n == nil then
			n = 1
		end

		if (n > 0 and n > (self._length - self._fillcount)) or
			  (n < 0 and n < (-self._fillcount)) then
			return BufferStatus.PRECONDITION_NOT_MET
		end

		self._wpos = (self._wpos + n + self._length) % self._length
		self._fillcount = self._fillcount + n
		self._wcount = self._wcount + n
		return BufferStatus.BUFFER_OK
    end

	-- データ書き込み
	-- @param value データ
	-- @return バッファステータス
	function obj:put(value)
		self._buffer[self._wpos+1] = value
		return BufferStatus.BUFFER_OK
	end

	-- データ書き込み
	-- @param value データ
	-- @param sec タイムアウト時間[s]
	-- @param nsec タイムアウト時間[ns]
	-- @return バッファステータス
	function obj:write(value, sec, nsec)
		if sec == nil then
			sec = -1
		end
		if nsec == nil then
			nsec = 0
		end
		if self:full() then
			local timedwrite = self._timedwrite
			local overwrite  = self._overwrite
			if overwrite then
				self:advanceRptr()
			else
				return BufferStatus.BUFFER_FULL
			end
			
		end

		self:put(value)
		self:advanceWptr(1)
		return BufferStatus.BUFFER_OK
	end

	-- 書き込み可能なバッファ残り長さ
	-- @return 長さ
	function obj:writable()
		return self._length - self._fillcount
	end

	-- バッファフルの判定
	-- @return true：バッファフル
	function obj:full()
		return (self._length == self._fillcount)
	end

	-- 指定位置まで読み込みポインタを進めた場合のバッファ取得
	-- @param n ポインタの位置
	-- @return 現在の位置のバッファ
	function obj:rptr(n)
		if n == nil then
			n = 0
		end
		return self._buffer[(self._rpos + n + self._length) % self._length + 1]
	end

	-- 読み込みポインタの位置を進める
	-- @param n ポインタの位置
	-- @return バッファステータス
	-- BUFFER_OK：正常に位置設定、PRECONDITION_NOT_MET：位置が不正
	function obj:advanceRptr(n)
		if n == nil then
			n = 1
		end

		if (n > 0 and n > self._fillcount) or
			  (n < 0 and n < (self._fillcount - self._length)) then
		  return BufferStatus.PRECONDITION_NOT_MET
		end

		self._rpos = (self._rpos + n + self._length) % self._length
		self._fillcount = self._fillcount - n
		return BufferStatus.BUFFER_OK
	end

	-- データ読み込み
	-- @param value value._dataにデータ格納
	-- @return バッファステータス(valueがnilの場合はバッファの値を返す)
	function obj:get(value)
		if value == nil then
			return self._buffer[self._rpos+1]
		end

		value._data = self._buffer[self._rpos+1]
		return BufferStatus.BUFFER_OK
	end

	-- データ読み込み
	-- @param value value._dataにデータ格納
	-- @param sec タイムアウト時間[s]、デフォルトは-1
	-- @param nsec タイムアウト時間[ns]、デフォルトは0
	-- @return バッファステータス
	-- BUFFER_OK：正常にデータ読み込み、BUFFER_EMPTY：バッファが空
	function obj:read(value, sec, nsec)
		if sec == nil then
			sec = -1
		end
		if nsec == nil then
			nsec = 0
		end
		if self:empty() then
			local timedread = self._timedread
			local readback  = self._readback
			if readback then
				if not (self._wcount > 0) then
					return BufferStatus.BUFFER_EMPTY
				end
				self:advanceRptr(-1)
			else
				return BufferStatus.BUFFER_EMPTY
			end
		end
		self:get(value)
		self:advanceRptr()
		return BufferStatus.BUFFER_OK
	end

	-- 読み込み可能なデータ長さ取得
	-- @return データ長さ
	function obj:readable()
		return self._fillcount
	end
	-- バッファが空かの判定
	-- @return true：空
	function obj:empty()
		return (self._fillcount == 0)
	end
	-- 初期化時にバッファ長さ設定
	-- @param prop プロパティ
	function obj:__initLength(prop)
		local n = tonumber(prop:getProperty("length"))
		if n ~= nil then
			self:length(n)
		end
	end
	-- バッファ書き込み時のポリシー設定
	-- @param prop プロパティ
	function obj:__initWritePolicy(prop)
		local policy = StringUtil.normalize(prop:getProperty("write.full_policy"))
		if policy == "overwrite" then
			self._overwrite  = true
      		self._timedwrite = false
		elseif policy == "do_nothing" then
			self._overwrite  = false
      		self._timedwrite = false
		end

	end
	-- バッファ読み込み時のポリシー設定
	-- @param prop プロパティ
	function obj:__initReadPolicy(prop)
		local policy = StringUtil.normalize(prop:getProperty("read.empty_policy"))
		if policy == "readback" then
			self._readback  = true
      		self._timedread = false
		elseif policy == "do_nothing" then
			self._readback  = false
      		self._timedread = false
		end
	end
	obj:reset()


	return obj
end


return RingBuffer
