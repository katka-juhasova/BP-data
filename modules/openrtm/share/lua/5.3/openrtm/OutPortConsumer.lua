---------------------------------
--! @file OutPortConsumer.lua
--! @brief OutPortコンシューマと生成ファクトリ定義
--! Pull型通信の独自インターフェース型を実装する場合は、
--! OutPortConsumerをメタテーブルに設定したコンシューマオブジェクトを生成する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortConsumer= {}
--_G["openrtm.OutPortConsumer"] = OutPortConsumer

local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory

-- OutPortコンシューマオブジェクト初期化
-- @return OutPortコンシューマオブジェクト
OutPortConsumer.new = function()
	local obj = {}
	obj.subscribe = {}
	-- コンシューマのインターフェース追加関数オブジェクト初期化
	-- @param prop プロパティ
	-- return インターフェース追加関数オブジェクト
	obj.subscribe.new = function(prop)
		local obj = {}
		obj._prop = prop
		-- インターフェース追加関数
		-- @param self 自身のオブジェクト
		-- @param consumer コンシューマ
		local call_func = function(self, consumer)
			consumer:subscribeInterface(self._prop)
		end
		setmetatable(obj, {__call=call_func})
		return obj
	end
	obj.unsubscribe = {}
	-- コンシューマのインターフェース削除関数オブジェクト初期化
	-- @param prop プロパティ
	-- return インターフェース削除オブジェクト
	obj.unsubscribe.new = function(prop)
		local obj = {}
		obj._prop = prop
		-- インターフェース削除関数
		-- @param self 自身のオブジェクト
		-- @param consumer コンシューマ
		local call_func = function(self, consumer)
			consumer:unsubscribeInterface(self._prop)
		end
		setmetatable(obj, {__call=call_func})
		return obj
	end
	return obj
end


OutPortConsumer.OutPortConsumerFactory = {}
setmetatable(OutPortConsumer.OutPortConsumerFactory, {__index=Factory.new()})

function OutPortConsumer.OutPortConsumerFactory:instance()
	return self
end


return OutPortConsumer
