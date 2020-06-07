---------------------------------
--! @file LogstreamBase.lua
--! @brief ロガーストリーム基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local LogstreamBase= {}
--_G["openrtm.LogstreamBase"] = LogstreamBase


local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory



-- ロガーストリーム基底オブジェクト初期化
-- @return ロガーストリーム
LogstreamBase.new = function()
	local obj = {}
	-- ログ出力
	-- @param msg 出力文字列
	-- @param level ログレベル
	-- @param name ロガー名
	-- @return true：出力成功、false：出力失敗
	function obj:log(msg, level, name)
		return false
	end
	-- ログレベル設定
	-- @param level ログレベル
	function obj:setLogLevel(level)
	end
	-- ロガー終了
	-- @return true；成功、false：失敗
	function obj:shutdown()
		return true
	end
	
	return obj
end


LogstreamBase.LogstreamFactory = {}
setmetatable(LogstreamBase.LogstreamFactory, {__index=Factory.new()})

function LogstreamBase.LogstreamFactory:instance()
	return self
end


return LogstreamBase
