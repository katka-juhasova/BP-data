---------------------------------
--! @file InPortConsumer.lua
--! @brief InPortコンシューマと生成ファクトリ定義
--! Push型通信の独自インターフェース型を実装する場合は、
--! InPortConsumerをメタテーブルに設定したコンシューマオブジェクトを生成する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local InPortConsumer= {}
--_G["openrtm.InPortConsumer"] = InPortConsumer

local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory

-- InPortコンシューマオブジェクト初期化
-- @return InPortコンシューマオブジェクト
InPortConsumer.new = function()
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


InPortConsumer.InPortConsumerFactory = {}
setmetatable(InPortConsumer.InPortConsumerFactory, {__index=Factory.new()})

function InPortConsumer.InPortConsumerFactory:instance()
	return self
end


return InPortConsumer
