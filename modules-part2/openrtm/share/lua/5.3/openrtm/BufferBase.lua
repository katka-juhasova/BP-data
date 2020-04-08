---------------------------------
--! @file BufferBase.lua
--! @brief バッファの基底クラス定義
--! バッファはBufferBaseテーブルをメタテーブルに設定して作成する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local BufferBase = {}
--_G["openrtm.BufferBase"] = BufferBase

local BufferStatus = require "openrtm.BufferStatus"

-- バッファ初期化
-- @return バッファオブジェクト
BufferBase.new = function()
	local obj = {}
	-- 初期化時にプロパティ設定
	-- @param prop プロパティ
	function obj:init(prop)
    end
    -- バッファ長設定
	-- @param n バッファ長
	-- @return バッファステータス(nがnilの場合は長さ)
	function obj:length(n)
		if n == nil then
			return 0
		end
		return BufferStatus.BUFFER_OK
    end
    -- バッファポインタをリセット
	function obj:reset()
    end
    -- 指定位置まで書き込みポインタを進めた場合のバッファ取得
	-- @param n ポインタの位置
	-- @return 現在の位置のバッファ
	function obj:wptr(n)
    end
    -- 書き込みポインタの位置を進める
	-- @param n ポインタの位置
	-- @return バッファステータス
	function obj:advanceWptr(n)
		return BufferStatus.BUFFER_OK
    end
    -- データ書き込み
	-- @param value データ
	-- @return バッファステータス
	function obj:put(data)
		return BufferStatus.BUFFER_OK
    end
    -- データ書き込み
	-- @param value データ
	-- @param sec タイムアウト時間[s]
	-- @param nsec タイムアウト時間[ns]
	-- @return バッファステータス
	function obj:write(value, sec, nsec)
		return BufferStatus.BUFFER_OK
    end
    -- 書き込み可能なバッファ残り長さ
	-- @return 長さ
	function obj:writable()
		return 0
    end
    -- バッファフルの判定
	-- @return true：バッファフル
	function obj:full()
		return true
    end
    
    -- 指定位置まで読み込みポインタを進めた場合のバッファ取得
	-- @param n ポインタの位置
	-- @return 現在の位置のバッファ
	function obj:rptr(n)
    end
    -- 読み込みポインタの位置を進める
	-- @param n ポインタの位置
	-- @return バッファステータス
	-- BUFFER_OK：正常に位置設定、PRECONDITION_NOT_MET：位置が不正
	function obj:advanceRptr(n)
		return BufferStatus.BUFFER_OK
    end
    -- データ読み込み
	-- @param value value._dataにデータ格納
	-- @return バッファステータス(valueがnilの場合はバッファの値を返す)
	function obj:get(value)
		return BufferStatus.BUFFER_OK
    end
	-- データ読み込み
	-- @param value value._dataにデータ格納
	-- @param sec タイムアウト時間[s]、デフォルトは-1
	-- @param nsec タイムアウト時間[ns]、デフォルトは0
	-- @return バッファステータス
	-- BUFFER_OK：正常にデータ読み込み、BUFFER_EMPTY：バッファが空
	function obj:read(value, sec, nsec)
		return BufferStatus.BUFFER_OK
    end
    -- 読み込み可能なデータ長さ取得
	-- @return データ長さ
	function obj:readable()
		return 0
    end
    -- バッファが空かの判定
	-- @return true：空
	function obj:empty()
		return true
    end
	return obj
end

BufferBase.NullBuffer = {}

-- 空のバッファ初期化
-- @return バッファオブジェクト
BufferBase.NullBuffer.new = function(size)
	local obj = {}
	setmetatable(obj, {__index=BufferBase.new()})
	return obj
end



return BufferBase
