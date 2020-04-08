---------------------------------
--! @file ConnectorBase.lua
--! @brief コネクタ基底クラス
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ConnectorBase= {}
--_G["openrtm.ConnectorBase"] = ConnectorBase


ConnectorBase.ConnectorInfo = {}

-- コネクタ情報格納オブジェクト初期化
-- @param name_ 名前
-- @param id_ コネクタID
-- @param ports_ ポートのリスト
-- @param properties_ 設定情報
-- @return コネクタ情報格納オブジェクト
ConnectorBase.ConnectorInfo.new = function(name_, id_, ports_, properties_)
	local obj = {}
	obj.name = name_
	obj.id = id_
	obj.ports = ports_
	obj.properties = properties_
	return obj
end

-- コネクタオブジェクト初期化
-- @return コネクタオブジェクト
ConnectorBase.new = function()
	local obj = {}
	-- コネクタプロファイル取得
	-- @return コネクタプロファイル
	function obj:profile()
	end
	-- コネクタID取得
	-- @return コネクタID
	function obj:id()
	end
	-- コネクタ名
	-- @return コネクタ名
	function obj:name()
	end
	-- コネクタ切断
	-- @return リターンコード
	function obj:disconnect()
	end
	-- バッファオブジェクト所得
	-- @return バッファオブジェクト
	function obj:getBuffer()
	end
	-- 	アクティブ化
	function obj:activate()
	end
	-- 	非アクティブ化
	function obj:deactivate()
	end
	return obj
end


return ConnectorBase
