---------------------------------
--! @file PublisherBase.lua
--! @brief パブリッシャー基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PublisherBase= {}
--_G["openrtm.PublisherBase"] = PublisherBase


local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory
local DataPortStatus = require "openrtm.DataPortStatus"

-- パブリッシャー基底オブジェクト初期化
-- @return パブリッシャー
PublisherBase.new = function()
	local obj = {}
	-- 初期化時にプロパティを設定
	-- @param prop プロパティ
	-- @return リターンコード
	function obj:init(prop)
		return DataPortStatus.PORT_OK
	end
	-- サービスコンシューマ設定
	-- @param consumer コンシューマオブジェクト
	-- @return リターンコード
	function obj:setConsumer(consumer)
		return DataPortStatus.PORT_OK
	end
	-- バッファ設定
	-- @param buffer バッファ
	-- @return リターンコード
	function obj:setBuffer(buffer)
		return DataPortStatus.PORT_OK
	end
	-- コールバック設定
	-- @param info プロファイル
	-- @param listeners コールバック関数
	-- @return リターンコード
	function obj:setListener(info, listeners)
		return DataPortStatus.PORT_OK
	end
	-- データ書き込み
	-- @param data データ
	-- @param sec タイムアウト時間[s]
	-- @param usec タイムアウト時間[us]
	-- @return リターンコード
	function obj:write(data, sec, usec)
		return DataPortStatus.PORT_OK
	end
	-- アクティブ状態化の確認
	-- @return true：アクティブ状態、false：非アクティブ状態
	function obj:isActive()
		return false
	end
	-- アクティブ化
	-- @return リターンコード
	function obj:activate()
		return DataPortStatus.PORT_OK
	end
	-- 非アクティブ化
	-- @return リターンコード
	function obj:deactivate()
		return DataPortStatus.PORT_OK
	end
	return obj
end


PublisherBase.PublisherFactory = {}
setmetatable(PublisherBase.PublisherFactory, {__index=Factory.new()})

function PublisherBase.PublisherFactory:instance()
	return self
end

return PublisherBase
