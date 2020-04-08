---------------------------------
--! @file ObjectManager.lua
--! @brief オブジェクトマネージャ定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ObjectManager= {}
--_G["openrtm.ObjectManager"] = ObjectManager


-- オブジェクトマネージャ初期化
-- @param predicate 一致判定関数オブジェクト
-- @return オブジェクトマネージャ
ObjectManager.new = function(predicate)
	local obj = {}
	obj._objects = {} --self.Objects()
	obj._predicate = predicate
	-- オブジェクト登録
	-- @param object オブジェクト
	-- @return true：登録成功、false：登録失敗
	function obj:registerObject(object)
		local predi = self._predicate({factory=object})
		for i, _obj in ipairs(self._objects) do
			if predi(_obj) == true then
				return false
			end
		end
		--print(#self._objects)
		table.insert(self._objects, object)
		--print(#self._objects)
		return true
	end
	-- オブジェクト登録解除
	-- @param id ID
	-- @return 登録解除したオブジェクト
	function obj:unregisterObject(id)
		local predi = self._predicate({name=id})
		for i, _obj in ipairs(self._objects) do
			if predi(_obj) == true then
				local ret = _obj
				table.remove(self._objects, i)
				return ret
			end
		end
		return nil
	end
	-- 指定関数を登録オブジェクト全てに実行
	-- @param p 関数オブジェクト初期化関数
	-- @return 関数オブジェクト
	function obj:for_each(p)
		local predi = p()
		for i, _obj in ipairs(self._objects) do
			predi(_obj)
		end
		return predi
	end
	-- idからオブジェクト検索
	-- @param id ID
	-- @return オブジェクト
	function obj:find(id)
		--print(id)
		local predi = nil
		if type(id) == "string" then
			predi = self._predicate({name=id})
		else
			predi = self._predicate({prop=id})
		end
		for i, _obj in ipairs(self._objects) do
			if predi(_obj) then
				return _obj
			end
		end
		return nil
	end
	-- 登録オブジェクト一覧取得
	-- @return 登録オブジェクト一覧
	function obj:getObjects()
		return self._objects
	end

	return obj
end


return ObjectManager
