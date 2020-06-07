---------------------------------
--! @file ECFactory.lua
--! @brief 実行コンテキスト生成用ファクトリ定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ECFactory= {}
--_G["openrtm.ECFactory"] = ECFactory

-- 実行コンテキスト削除関数
-- @param ec 実行コンテキスト
ECFactory.ECDelete = function(ec)
end


ECFactory.ECFactoryBase = {}

-- 実行コンテキスト生成ファクトリ基底オブジェクトの初期化関数
-- @return 実行コンテキスト生成ファクトリ
ECFactory.ECFactoryBase.new = function()
	local obj = {}
	-- 実行コンテキスト名取得
	-- @return 実行コンテキスト名
	function obj:name()
		return ""
	end
	-- 実行コンテキスト生成
	-- @return 実行コンテキスト
	function obj:create()
	end
	-- 実行コンテキスト削除
	-- @param ec 実行コンテキスト
	function obj:destroy(ec)
	end
	return obj
end

ECFactory.ECFactoryLua = {}

-- 実行コンテキスト生成ファクトリの初期化関数
-- @param name 実行コンテキスト名
-- @param new_func 実行コンテキスト初期化関数
-- 実行コンテキストを返す関数を指定する
-- @param delete_func 実行コンテキスト削除関数
-- 実行コンテキストを引数とする関数を指定
-- @return 実行コンテキスト生成ファクトリ
ECFactory.ECFactoryLua.new = function(name, new_func, delete_func)
	local obj = {}
	setmetatable(obj, {__index=ECFactory.ECFactoryBase.new()})
	obj._name   = name
    obj._New    = new_func
    obj._Delete = delete_func
   	-- 実行コンテキスト名取得
	-- @return 実行コンテキスト名
	function obj:name()
		return self._name
	end
	-- 実行コンテキスト生成
	-- @return 実行コンテキスト
	function obj:create()
		return self._New()
	end
	-- 実行コンテキスト削除
	-- @param ec 実行コンテキスト
	function obj:destroy(ec)
		self._Delete(ec)
	end
	return obj
end


return ECFactory
