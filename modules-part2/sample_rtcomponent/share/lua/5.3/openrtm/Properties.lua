---------------------------------
--! @file Properties.lua
--! @brief プロパティ操作関数定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local Properties= {}
--_G["openrtm.Properties"] = Properties

local StringUtil = require "openrtm.StringUtil"
--string = require string

-- プロパティ初期化
-- @param argv argv.prop：コピー元のプロパティ、argv.key・argv.value：キーと値、argv.defaults_map：テーブル
Properties.new = function(argv)
	local obj = {}
	function obj:init()
		self.default_value = ""
		self.root = nil
		self.empty = ""
		self.leaf = {}
		self.name  = ""
		self.value = ""
		if argv == nil then
			argv = {}
		end
		if argv.prop ~= nil then
			--print(argv.prop:str())
			self.name = argv.prop.name
			self.value = argv.prop.value
			self.default_value = argv.prop.default_value
			local keys = argv.prop:propertyNames()
			--print(#keys)
			for i, _key in ipairs(keys) do
				--print(i, _key)
				local node = argv.prop:getNode(_key)
				--print(node)
				if node ~= nil then
					--print(_key, node.default_value)
					self:setDefault(_key, node.default_value)
					self:setProperty(_key, node.value)
				end
			end
		end
		if argv.key ~= nil then
			self.name = argv.key
			if argv.value == nil then
				self.value = ""
			else
				self.value = argv.value
			end
		end
		if argv.defaults_map ~= nil then
			for _key, _value in pairs(argv.defaults_map) do
				_key = StringUtil.eraseBothEndsBlank(_key)
				_value = StringUtil.eraseBothEndsBlank(_value)
				self:setDefault(_key, _value)
			end
		end
		--[[
		if argv.defaults_str ~= nil then
			local _num = argv.num
			if argv.num == nil then
				_num = 100000
			end
			self:setDefaults(argv.defaults_str, _num)
		end
		]]
	end
	-- キー取得
	-- @return キー
	function obj:getName()
		return self.name
	end
	-- 値取得
	-- @return 値
	function obj:getValue()
		return self.value
	end
	-- デフォルト値取得
	-- @param key キー
	-- @param default デフォルト値
	-- @return 値
	function obj:getDefaultValue(key, default)
		return self.default_value
	end
	-- ルート要素の取得
	-- @return ルート要素
	function obj:getRoot()
		return self.root
	end
	-- プロパティ値取得
	-- @param key キー
	-- @param default デフォルト値
	-- @return プロパティ
	function obj:getProperty(key, default)
		--print(key)
		if default == nil then
			local keys = StringUtil.split(key, "%.")
			local node = self:_getNode(keys, 1, self)
			if node then
				if node.value ~= "" then
					return node.value
				else
					return node.default_value
				end
			end
			return self.empty
		else
			local value = self:getProperty(key)
			if value ~= "" then
				return value
			else
				return default
			end
		end
	end
	-- デフォルト値取得
	-- @param key キー
	-- @return デフォルト値
	function obj:getDefault(key)
		local keys = StringUtil.split(key, "%.")
		local node = self:_getNode(keys, 1, self)
		if node ~= nil then
			return node.default_value
		end
		return self.empty
	end
	-- プロパティ設定
	-- @param key キー
	-- @param value 値
	-- @return プロパティ
	function obj:setProperty(key, value)
		--print(self.leaf)
		if value ~= nil then
			local keys = StringUtil.split(key, "%.")
			--print(key,#keys)
			local curr = self
			for _i, _key in ipairs(keys) do
				--print(curr)
				local _next = curr:hasKey(_key)
				if _next == nil then
					_next = Properties.new({key=_key})
					_next.root = curr
					table.insert(curr.leaf,_next)
				end
				curr = _next
			end

			curr.value = value
			return retval
		else
			--print(self:getProperty(key))
			self:setProperty(key, self:getProperty(key))
			local prop = self:getNode(key)
			return prop.value
		end
		return self.root
	end
	-- デフォルト値設定
	-- @param key キー
	-- @param value デフォルト値
	-- @return 値
	function obj:setDefault(key, value)
		local keys = StringUtil.split(key, "%.")
		local curr = self
		--print(self.leaf)
		--StringUtil.print_table(keys)
		for _i, _key in ipairs(keys) do
			local _next = curr:hasKey(_key)
			if _next == nil then
				_next = Properties.new({key=_key})
				_next.root = curr
				--print(curr.leaf, _next)
				--print(#curr.leaf)
				table.insert(curr.leaf, _next)
			end
			curr= _next
		end
		if value ~= "" and string.sub(value, -1) ~= "\n" then
			value = string.sub(value, 0, -1)
		end
		curr.default_value = value
		return value
	end
	--デフォルト値をテーブルから設定
	-- @param defaults デフォルト値のテーブル
	-- @param num 最大数
	-- @return プロパティ
	function obj:setDefaults(defaults, num)
		if num == nil then
			num = 10000
		end

		--[[for i = 1, #defaults/2 do
			if i > num then
				break
			end
			local _key = defaults[i*2-1]
			local _value = defaults[i*2]
			--print(_key, _value)
			_key = StringUtil.eraseHeadBlank(_key)
			_key = StringUtil.eraseTailBlank(_key)
			_value = StringUtil.eraseHeadBlank(_value)
			_value = StringUtil.eraseTailBlank(_value)
			self:setDefault(_key, _value)
		end
		]]
		local count = 1
		for _key,_value in pairs(defaults) do
			if num < count then
				break
			end
			_key = StringUtil.eraseBothEndsBlank(_key)
			_value = StringUtil.eraseBothEndsBlank(_value)
			self:setDefault(_key, _value)
			count = count+1
		end
		return self.leaf
	end
	-- 指定ストリームにプロパティを出力
	-- @param out アウトストリーム
	function obj:list(out)
		self:_store(out, "", self)
		return
	end
	-- 指定ストリームからプロパティを入力
	-- @param inStream インストリーム
	-- @return プロパティ
	function obj:loadStream(inStream)
		pline = ""
		for i, readStr in ipairs(inStream) do
			if readStr ~= "" then
				local _str = readStr
				_str = StringUtil.eraseHeadBlank(_str)
				local s = string.sub(_str,0,1)
				if s == "#" or s == "!" or s == "\n" then
				else
					--_str = _str.rstrip('\r\n')
					if string.sub(_str,-1) == "\\" and not StringUtil.isEscaped(_str, #_str-1) then
						local tmp = string.sub(_str,0,-1)
						tmp = StringUtil.eraseTailBlank(tmp)
						pline = pline..tmp
					else
						pline = pline.._str
						local key, value = self:splitKeyValue(pline)
						key = StringUtil.unescape(key)
						key = StringUtil.eraseHeadBlank(key)
						key = StringUtil.eraseHeadBlank(key)
						value = StringUtil.unescape(value)
						value = StringUtil.eraseHeadBlank(value)
						value = StringUtil.eraseHeadBlank(value)
						self:setProperty(key, value)
						pline = ""
					end
				end
			end
		end
		return self.leaf
	end
	-- 指定ストリームにヘッダを記述したプロパティを出力
	-- @param out アウトストリーム
	-- @param header ヘッダ
	function obj:store(out, header)
		out.write("#"..header.."\n")
		self:_store(out, "", self)
	end
	-- プロパティのキー一覧を取得
	-- @return キー一覧
	function obj:propertyNames()
		local names = {}
		for i, leaf in ipairs(self.leaf) do
			self:_propertyNames(names, leaf.name, leaf)
		end
		return names
	end
	-- プロパティのキーの数取得
	-- @return キーの数
	function obj:size()
		return #self:propertyNames()
	end
	-- 指定キーのノードを検索
	-- @param key キー
	-- @return ノード
	function obj:findNode(key)
		if key == nil then
			return nil
		end
		--keys = {}
		--self:split(key, '%.', keys)
		local keys = StringUtil.split(key, "%.")
		--print(keys[0])
		--print(self:_getNode(keys, 1, self))
		return self:_getNode(keys, 1, self)
	end
	-- 指定キーのノードを取得
	-- @param key キー
	-- @return ノード
	function obj:getNode(key)
		if key == nil then
			return self
		end
		local leaf = self:findNode(key)
		--print(leaf, type(leaf))

		if leaf ~= nil then
			return leaf
		end
		self:createNode(key)
		--print(self:findNode(key), type(self:findNode(key)))
		return self:findNode(key)
	end
	-- 指定キーのノードを生成
	-- @param key キー
	-- @return true：生成成功、false：生成失敗
	function obj:createNode(key)
		if key == "" then
			return false
		end
		if self:findNode(key) ~= nil then
			return false
		end
		self:setProperty(key,"")
		return true
	end
	-- ノード削除
	-- @param leaf_name キー
	-- @return プロパティ
	function obj:removeNode(leaf_name)
		for i, leaf in ipairs(self.leaf) do
			if leaf.name == leaf_name then
				local prop = leaf
				table.remove(self.leaf, i)
				return prop
			end
		end
		return nil

	end
	-- キーの存在確認
	-- @param key キー
	-- @return プロパティ
	function obj:hasKey(key)
		--print(self.leaf)
		for i, leaf in ipairs(self.leaf) do
			if leaf.name == key then
				return leaf
			end
		end
		return nil
	end
	-- プロパティ全削除
	function obj:clear()
		self.leaf = {}
	end
	-- プロパティの追加
	-- @param prop 追加元のプロパティ
	-- @return 追加先のプロパティ
	function obj:mergeProperties(prop)
		local keys = prop:propertyNames()
		for i = 1, prop:size() do
			self:setProperty(keys[i], prop:getProperty(keys[i]))
		end
		return self
	end
	-- 文字列からキーと値を取り出し
	-- @param _str 文字列(key:value)
	-- @param key キー一覧
	-- @param value 値一覧
	-- @return プロパティ
	function obj:splitKeyValue(_str)

		local key = ""
		local value = ""
		local length = #_str
		for i = 1, length do
			local s = string.sub(_str,i,i)
			if (s == ":" or s == "=") and not StringUtil.isEscaped(_str, i) then
				key = string.sub(_str,1,i-1)
				value = string.sub(_str,i+1)
				return key, value
			end
		end
		for i = 1, length do
			if s == " " and not StringUtil.isEscaped(_str, i) then
				key = string.sub(_str,1,i-1)
				value = string.sub(_str,i+1)			
				return key, value
			end
		end
		key = _str
		value = ""
		return key, value
	end
	-- 文字列を分割する
	-- @param _str 文字列
	-- @param delim 分割文字
	-- @param value 値一覧
	-- @return true；分割成功、false：分割失敗
	function obj:split( _str, delim, value)
		if _str == "" then
			return false
		end
		local begin_it = 0
		local length = #_str
		for end_it = 1,length do
			if string.sub(_str,end_it,end_it) == delim and not StringUtil.isEscaped(_str, end_it) then
				table.insert(value,string.sub(_str,begin_it, end_it))
				begin_it = end_it+1
			end
		end
		return true
	end
	-- ノード取得
	-- @param keys キー一覧
	-- @param index キー一覧のインデックス
	-- @param curr 現在のノード
	-- @return 次のノード
	function obj:_getNode(keys, index, curr)
		--print(keys[index])
		local _next = curr:hasKey(keys[index])
		--print(_next)
		if _next == nil then
			return nil
		end
		if index < #keys then
			index = index + 1
			return _next:_getNode(keys, index, _next)
		else
			return _next
		end
	end
	-- ノードのキー一覧取得
	-- @param names キー一覧
	-- @param curr_name 現在探索しているキー
	-- @param curr 現在のノード
	function obj:_propertyNames(names, curr_name, curr)
		if #curr.leaf > 0 then
			for i = 1, #curr.leaf do
				local next_name = curr_name.."."..curr.leaf[i].name
				self:_propertyNames(names, next_name, curr.leaf[i])
			end
		else
			table.insert(names,curr_name)
		end
	end
	-- 指定ストリームにプロパティを出力
	-- @param out アウトストリーム
	-- @param curr_name 現在のキー
	-- @param curr 現在のノード
	function obj:_store(out, curr_name, curr)
		if #curr.leaf > 0 then
			for i = 1, #curr.leaf do
				local next_name = ""
				if curr_name == "" then
					next_name = curr.leaf[i].name
				else
					next_name = curr_name+"."+curr.leaf[i].name
				end
				self:_store(out, next_name, curr.leaf[i])
			end
		else
			local val = curr.value
			if val == "" then
				val = curr.default_value
				out.write(curr_name..": "..val.."\n")
			end
		end
	end
	-- インデント生成
	-- @param index 現在のインデント数
	-- @return インデント
	function obj:indent(index)
		--print("indent")
		local space = ""
		for i = 1, index-1 do
			space = space.."  "
		end
		return space
	end
	-- プロパティを出力用に文字列に変換
	-- @param out 出力文字列
	-- @param curr 現在のノード
	-- @param index インデント数
	-- @return 文字列
	function obj:_dump(out, curr, index)
		if index ~= 0 then
			out[1] = out[1]..self:indent(index).."- "..curr.name
		end
		if #curr.leaf == 0 then
			--print("test",curr.default_value, curr.value)
			if curr.value == "" then
				out[1] = out[1]..": "..tostring(curr.default_value).."\n"
			else
				out[1] = out[1]..": "..tostring(curr.value).."\n"
			end
			return out[1]
		end
		if index ~= 0 then
			out[1] = out[1].."\n"
		end
		for i = 1, #curr.leaf do
			self:_dump(out, curr.leaf[i], index + 1)
		end
		return out[1]
	end
	-- プロパティ取得
	-- @return プロパティ
	function obj:getLeaf()
		return self.leaf
	end

	-- ファイルストリームからプロパティを設定
	-- @param inStream ファイルストリーム
	function obj:load(inStream)
		local pline = ""
		for readStr in inStream:lines() do
			
			local _str = StringUtil.eraseHeadBlank(readStr)


			if string.sub(_str,1,1) == "#" or string.sub(_str,1,1) == "!" or string.sub(_str,1,1) == "\n" then
			else

				_str = StringUtil.eraseHeadBlank(_str)

				if string.sub(_str, #_str, #_str) == "\\" and not StringUtil.isEscaped(_str, #_str) then

					local tmp = string.sub(_str,1,#_str-1)
					tmp = StringUtil.eraseTailBlank(tmp)

					pline = pline..tmp
				else
					pline = pline.._str

					
					--print(key)
					local key, value = self:splitKeyValue(pline)
					key = StringUtil.unescape(key)
					key = StringUtil.eraseHeadBlank(key)
					key = StringUtil.eraseTailBlank(key)

					value = StringUtil.unescape(value)
					value = StringUtil.eraseHeadBlank(value)
					value = StringUtil.eraseTailBlank(value)
					--print(value)
					--print(key, value)
					self:setProperty(key, value)
					pline = ""
				end
			end
		end
	end
	-- 文字列変換関数
	-- @param self 自身のオブジェクト
	-- @return 変換後の文字列
	local str_func = function(self)
		local str = {}
		table.insert(str,"")
		--print(self._dump)
		return self:_dump(str, self, 0)
	end
	obj:init()

	setmetatable(obj, {__tostring =str_func})
	return obj
end


return Properties
