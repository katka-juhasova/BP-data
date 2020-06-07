---------------------------------
--! @file GlobalFactory.lua
--! @brief オブジェクト生成ファクトリ定義
--! FACTORY_OK：正常
--! FACTORY_ERROR：エラー
--! ALREADY_EXISTS：既に指定ファクトリが存在
--! NOT_FOUND：指定ファクトリがない
--! INVALID_ARG：不正な引数
--! UNKNOWN_ERROR：それ以外のエラー
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local GlobalFactory= {}
--_G["openrtm.GlobalFactory"] = GlobalFactory

GlobalFactory.Factory = {}

GlobalFactory.Factory.FACTORY_OK = 0
GlobalFactory.Factory.FACTORY_ERROR = 1
GlobalFactory.Factory.ALREADY_EXISTS = 2
GlobalFactory.Factory.NOT_FOUND = 3
GlobalFactory.Factory.INVALID_ARG = 4
GlobalFactory.Factory.UNKNOWN_ERROR = 5

local FactoryEntry = {}

-- オブジェクト生成ファクトリ関数初期化
-- @param id 識別子
-- @param creator 生成関数
-- @param destructor 削除関数
-- @return 生成オブジェクト
function FactoryEntry.new(id, creator, destructor)
	local obj = {}
	obj.id_ = id
	obj.creator_ = creator
	obj.destructor_ = destructor
	return obj
end

-- ファクトリ登録オブジェクト初期化
-- @return ファクトリ登録オブジェクト
GlobalFactory.Factory.new = function()
	local obj = {}
	obj._creators = {}
	obj._objects = {}
	-- 指定IDのファクトリが存在するかの確認
	-- @param id 識別子
	-- @return true：存在する、false：存在しない
	function obj:hasFactory(id)
		if self._creators[id] == nil then
			return false
		else
			return true
		end
	end
	
	-- 登録ファクトリのID一覧を取得
	-- @return ID一覧
	function obj:getIdentifiers()
		local idlist = {}
		for i, ver in pairs(self._creators) do
			table.insert(idlist, i)
		end
		return idlist
	end

	-- ファクトリ追加
	-- @param id 識別子
	-- @param creator 生成関数
	-- @param destructor 削除関数
	-- @return リターンコード
	-- FACTORY_OK：正常に追加
	-- ALREADY_EXISTS：既に指定IDで追加済み
	-- INVALID_ARG：不正な引数
	function obj:addFactory(id, creator, destructor)
		--print("test",creator,destructor)
		if creator == nil or destructor == nil then
			return GlobalFactory.Factory.INVALID_ARG
		end

		if self._creators[id] ~= nil then
			return GlobalFactory.Factory.ALREADY_EXISTS
		end

		self._creators[id] = FactoryEntry.new(id, creator, destructor)
		return GlobalFactory.Factory.FACTORY_OK
	end


	-- ファクトリ削除
	-- @param id 識別子
	-- @return リターンコード
	-- FACTORY_OK：正常に削除
	-- NOT_FOUND：ファクトリがない
	function obj:removeFactory(id)

		if self._creators[id] == nil then
			return GlobalFactory.Factory.NOT_FOUND
		end

		self._creators[id] = nil
		return GlobalFactory.Factory.FACTORY_OK
	end

	-- 指定オブジェクトを生成
	-- @param id 識別子
	-- @return オブジェクト
	function obj:createObject(id)

		if self._creators[id] == nil then
			print("Factory.createObject return nil id: "..id)
			return nil
		end

		local obj_ = self._creators[id].creator_()
		self._objects[obj_] = self._creators[id]
		--for k,v in pairs(self._objects) do
		--	print(k,v)
		--end
		return obj_
	end

	-- 指定オブジェクトを削除
	-- @param obj オブジェクト
	-- @param id 識別子
	-- @return リターンコード
	-- FACTORY_OK：正常に削除
	-- NOT_FOUND：オブジェクトがない
	function obj:deleteObject(obj, id)

		if id ~= nil then
			if self._creators[id] == nil then
				self._creators[id].destructor_(obj)
				self._creators[id] = nil
				return GlobalFactory.Factory.FACTORY_OK
			end
		end

		if self._objects[obj] == nil then
			return GlobalFactory.Factory.NOT_FOUND
		end

		tmp = obj
		self._objects[obj].destructor_(obj)
		--print(#self._objects)

		--for k,v in pairs(self._objects) do
		--	print(k,v)
		--end
		self._objects[obj] = nil
		--print(#self._objects)
		return GlobalFactory.Factory.FACTORY_OK
	end

	-- 作成済みオブジェクト一覧を取得
	-- @return 作成済みオブジェクト一覧
	function obj:createdObjects()

		objects_ = {}
		for i, ver in pairs(self._objects) do
			table.insert(objects_, ver)
		end
		return objects_
	end


	-- 指定オブジェクトの存在確認
	-- true：存在する、false：存在しない
	function obj:isProducerOf(obj)

		if self._objects[obj] ~= nil then
			return true
		else
			return false
		end

	end

	-- 指定オブジェクトのID取得
	-- @param obj オブジェクト
	-- @return ID、リターンコード
	function obj:objectToIdentifier(obj)

		if self._objects[obj] == nil then
			return -1, GlobalFactory.Factory.NOT_FOUND
		end
		local id = self._objects[obj].id_
		return id, GlobalFactory.Factory.FACTORY_OK
	end

	-- 指定オブジェクトの生成関数を取得
	-- @param obj オブジェクト
	-- @return 生成関数
	function obj:objectToCreator(obj)
		if not self:isProducerOf(obj) then
			return nil
		end
		return self._objects[obj].creator_
	end

	-- 指定オブジェクトの削除関数を取得
	-- @param obj オブジェクト
	-- @return 削除関数
	function obj:objectToDestructor(obj)
		if not self:isProducerOf(obj) then
			return nil
		end
		return self._objects[obj].destructor_
	end
	return obj
end


GlobalFactory.GlobalFactory = {}
setmetatable(GlobalFactory.GlobalFactory, {__index=GlobalFactory.Factory.new()})



function GlobalFactory.GlobalFactory:instance()
	return self
end


return GlobalFactory
