---------------------------------
--! @file BufferStatus.lua
--! @brief バッファの状態定義
--! BUFFER_OK：正常
--! BUFFER_ERROR：エラー
--! BUFFER_FULL：バッファフル
--! BUFFER_EMPTY：バッファエンプティ
--! NOT_SUPPORTED：サポート外の操作
--! TIMEOUT：タイムアウト
--! PRECONDITION_NOT_MET：それ以外の異常
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]



local BufferStatus = {
				BUFFER_OK = 0,
				BUFFER_ERROR = 1,
				BUFFER_FULL = 2,
				BUFFER_EMPTY = 3,
				NOT_SUPPORTED = 4,
				TIMEOUT = 5,
				PRECONDITION_NOT_MET = 6
				}
				
--_G["openrtm.BufferStatus"] = BufferStatus

-- バッファステータスを文字に変換
-- @param status バッファステータス
-- @return 文字列化したバッファステータス
BufferStatus.toString = function(status)
	str = {"BUFFER_OK",
           "BUFFER_ERROR",
           "BUFFER_FULL",
           "BUFFER_EMPTY",
           "NOT_SUPPORTED",
           "TIMEOUT",
           "PRECONDITION_NOT_MET"}
	return str[status+1]
end

return BufferStatus
