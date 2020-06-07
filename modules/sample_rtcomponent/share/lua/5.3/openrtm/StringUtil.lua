---------------------------------
--! @file StringUtil.lua
--! @brief 文字列操作関数定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local StringUtil= {}
--_G["openrtm.StringUtil"] = StringUtil


-- 文字列先頭の空白削除
-- @param _str 文字列
-- @return 空白削除後の文字列
StringUtil.eraseHeadBlank = function(_str)
	return (string.gsub(_str, "^%s*(.-)$", "%1"))
end

-- 文字列末尾の空白削除
-- @param _str 文字列
-- @return 空白削除後の文字列
StringUtil.eraseTailBlank = function(_str)
	return (string.gsub(_str, "^(.-)%s*$", "%1"))
end

-- 文字列先頭と末尾の空白削除
-- @param _str 文字列
-- @return 空白削除後の文字列
StringUtil.eraseBothEndsBlank = function(_str)
	return (string.gsub(_str, "^%s*(.-)%s*$", "%1"))
end


-- 文字列の正規化
-- @param _str 文字列
-- @return 正規化後の文字列
StringUtil.normalize = function(_str)
	local ret = string.gsub(_str, "^%s*(.-)%s*$", "%1")
	return string.lower(ret)
end

-- リストの要素全ての文字列の前後の空白を削除
-- @param str_list 文字列のリスト
-- @return 前後の空白削除後の文字列のリスト
StringUtil.strip = function(str_list)
	local ret = {}
	for k,v in ipairs(str_list) do
		table.insert(ret, StringUtil.eraseBothEndsBlank(v))
	end
	return ret
end

-- 文字列にエスケープ文字が含まれるかを判定
-- @param _str 文字列
-- @param pos 位置
-- @return true；エスケープ文字が含まれる、false：含まれない
StringUtil.isEscaped = function(_str, pos)
	--pos = pos-1

	local i = 0
	--print(string.sub(_str, pos, pos))
	while pos >= 0 and string.sub(_str, pos, pos) == "\\" do
		i = i+1
		pos = pos-1
	end

	return (i % 2 == 1)
end


local unescape_functor = {}
-- エスケープ文字に変換する関数オブジェクト初期化
-- @return 関数オブジェクト
unescape_functor.new = function()
	local obj = {}
	obj.count  = 0
	obj._str  = ""
	-- エスケープ文字に変換する
	-- @param self 自身のオブジェクト
	-- @param c 文字
	local call_func = function(self, c)
		if c == "\\" then
			self.count = self.count+1
			if self.count % 2 == 0 then
				self._str = self._str..c
			end
		else
			if self.count > 0 and self.count % 2 == 1 then
				self.count = 0
				if c == 't' then
					self._str=self._str..'\t'
				elseif c == 'n' then
					self._str=self._str..'\n'
				elseif c == 'f' then
					self._str=self._str..'\f'
				elseif c == 'r' then
					self._str=self._str..'\r'
				elseif c == '\"' then
					self._str=self._str..'\"'
				elseif c == '\'' then
					self._str=self._str..'\''
				else
					self._str=self._str..c
				end
			else
				self.count = 0
				self._str=self._str..c
			end
		end
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

-- 文字列のアンエスケープ
-- @param _str 文字列
-- @return アンエスケープ後の文字列
StringUtil.unescape = function(_str)
	local functor = unescape_functor.new()
	for i=1,#_str do
		functor(string.sub(_str,i,i))
	end
	return functor._str
end

-- テーブルのコピー
-- @param orig コピー物のテーブル
-- @return コピー後のテーブル
StringUtil.copy = function(orig)
	local copy = {}
	if type(orig) == 'table' then
		for k, v in ipairs(orig) do
			copy[k] = v
		end
	else
		copy = orig
	end
	return copy
end

-- テーブルのコピー
-- @param orig コピー物のテーブル
-- @return コピー後のテーブル
StringUtil.deepcopy = function(orig)
	local copy = {}
	if type(orig) == 'table' then
		for k, v in pairs(orig) do
			copy[k] = StringUtil.deepcopy(v)
		end
	else
		copy = orig
	end
	return copy
end



-- 文字列の分割
-- @param input 文字列
-- @param delimiter 分割文字
-- @return 文字列のリスト
StringUtil.split = function(input, delimiter)
	--print(input:find(delimiter))
	if string.find(input, delimiter) == nil then
		return { input }
	end
	local result = {}
	local pat = "(.-)" .. delimiter .. "()"
    local lastPos = 0
    for part, pos in string.gmatch(input, pat) do
		table.insert(result, part)
        lastPos = pos
    end
    table.insert(result, string.sub(input, lastPos))
    return result
end

-- テーブルを標準出力
-- @param tbl テーブル
StringUtil.print_table = function(tbl)
	for k, v in pairs(tbl) do
		if type(v)=="table" then
			--print( k..":" )
			StringUtil.print_table(v)
		else
			print( k, v )
		end
	end
end

-- 文字列をboolに変換
-- @param _str 文字列
-- @param yes trueの場合の文字列
-- @param no falseの場合の文字列
-- @param default_value デフォルト値
-- @return bool値
StringUtil.toBool = function(_str, yes, no, default_value)
	if default_value == nil then
		default_value = true
	end
	--print(_str)
	_str = _str:lower()
	yes = yes:lower()
	no = no:lower()
	if _str:match(yes) ~= nil then
		return true
	elseif _str:match(no) ~= nil then
		return false
	end
	return default_value
end



-- 数値を文字列に変換
-- @param n 数値
-- @return 文字列
StringUtil.otos = function(n)
	return ""..n
end

-- テーブルに値が含まれるかの判定
-- @param tbl テーブル
-- @param val 値
-- @return true；含まれる、false：含まれない
StringUtil.in_value = function(tbl, val)
    for k, v in pairs (tbl) do
        if v==val then
			return true
		end
    end
    return false
end

-- テーブルにキーが含まれるかの判定
-- @param tbl テーブル
-- @param key キー
-- @return true；含まれる、false：含まれない
StringUtil.in_key = function(tbl, key)
	if tbl[key] ~= nil then
		return true
	end
    return false
end

-- テーブルから重複する値を削除
-- @param sv テーブル
-- @return 値削除後のテーブル
StringUtil.unique_sv = function(sv)
	local unique_strvec = StringUtil.unique_strvec.new()
	for i,v in ipairs(sv) do
		unique_strvec(v)
	end
	return unique_strvec._str
end

StringUtil.unique_strvec = {}

-- テーブルに同じ値が含まれなかった場合に追加する関数オブジェクト初期化
-- @return 関数オブジェクト
StringUtil.unique_strvec.new = function()
	local obj = {}
	obj._str = {}
	-- テーブルに同じ値が含まれなかった場合に追加する
	-- @param self 自身のオブジェクト
	-- @param s 値
	-- @return テーブル
	local call_func = function(self, s)
		if not StringUtil.in_value(self._str, s) then
			table.insert(self._str, s)
			return self._str
		end
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

-- テーブルを文字列に変換
-- @param sv テーブル
-- @param delimiter 区切り文字
-- @return 文字列
StringUtil.flatten = function(sv, delimiter)
	if delimiter == nil then
		delimiter = ", "
	end
	if #sv == 0 then
		return ""
	end
	local _str = table.concat(sv, delimiter)

	return _str
end

-- テーブルに指定の値が含まれる数を取得
-- @param tbl テーブル
-- @param value 値
-- @return 含まれていた数
StringUtil.table_count = function(tbl, value)
	local count = 0
	for i, v in ipairs(tbl) do
		if value == v then
			count = count+1
		end
	end
	return count
end

-- テーブルに指定の値が何番目に含まれているかを取得
-- @param tbl テーブル
-- @param value 値
-- @return キー
StringUtil.table_index = function(tbl, value)
	for i, v in ipairs(tbl) do
		if value == v then
			return i
		end
	end
	return -1
end

-- テーブルに値が含まれるかの確認
-- @param _list テーブル、文字列の場合はテーブルに変換
-- @param value 値
-- @param ignore_case true：小文字化して判定
-- @return true：含まれる、false：含まれない
StringUtil.includes = function(_list, value, ignore_case)
	if ignore_case == nil then
		ignore_case = true
	end

	if not (type(_list) == "table" or type(_list) == "string") then

		return false
	end

	if type(_list) == "string" then
		_list = StringUtil.split(_list, ",")
	end


	local tmp_list = _list
	if ignore_case then
		value = string.lower(value)
		tmp_list = {}
		for i, v in ipairs(_list) do
			table.insert(tmp_list, string.lower(v))
		end
	end
	if StringUtil.table_count(tmp_list, value) > 0 then
		return true
	end

	return false
end

-- 文字列をリストに変換
-- @param _type 変換後の型
-- @param _str 文字列
-- @return ret(true：変換成功),リスト
StringUtil._stringToList = function(_type, _str)

	local list_ = StringUtil.split(_str, ",")
	local ans = {}
	if #_type < #list_ then
		local sub = #list_ - #_type
		for i = 1,sub do
			table.insert(_type, _type[1])
		end
	elseif #_type > #list_ then
		local sub = #_type - #list_
		for i = #list_,#_type do
			table.remove(_type, i)
		end
	end
	for i = 1,#list_ do
		if type(_type[i]) == "number" then
			table.insert(ans, tonumber(list_[i]))
		elseif type(_type[i]) == "string" then
			table.insert(ans, tostring(list_[i]))
		end
	end

	return true, ans


end

-- 文字列を指定した型に変換
-- @param _type 変換後の型
-- @param _str 文字列
-- @return ret(true：変換成功、false：変換失敗)、変換後の値
StringUtil.stringTo = function(_type, _str)
	if type(_type) == "number" then
		local value = tonumber(_str)
		if value ~= nil then
			return true, value
		else
			return false, _type
		end
	elseif type(_type) == "string" then
		local value = tostring(_str)
		if value ~= nil then
			return true, value
		else
			return false, _type
		end
	elseif type(_type) == "table" then
		return StringUtil._stringToList(_type, _str)
	else
		return false, _type
	end

end

-- 文字列から設定か可能なオプションのリスト取得
-- @param options 文字列
-- @return オプション一覧。optargがtrueの場合はオプションの後ろに値を設定する。
StringUtil.createopt = function(options)
	local ret = {}
	local pos = 1
	while pos <= #options do
		local opt = string.sub(options,pos,pos)
		ret[opt] = {}
		pos = pos + 1
		if pos <= #options then
			local opt2 = string.sub(options,pos,pos)
			if opt2 == ":" then
				ret[opt].optarg = true
				pos = pos + 1
			else
				ret[opt].optarg = false
			end
		end
	end
	return ret
end

-- 文字列からオプション取得
-- @param arg 文字列
-- @param options オプション一覧の文字列
-- @return オプション一覧。optargに値が入る。
StringUtil.getopt = function(arg, options)
	local ret = {}
	local pos = 1
	local opt = StringUtil.createopt(options)
	--for i,v in pairs(opt) do
	--	print(i,v.value)
	--end
	while pos <= #arg do
		arg[pos] = StringUtil.eraseBothEndsBlank(arg[pos])
		if #arg[pos] <= 1 then
			pos = pos + 1
		elseif string.sub(arg[pos],1,1) == "-" then
			local _id = string.sub(arg[pos],2)
			if opt[_id] ~= nil then
				local v = {id=_id}
				if opt[_id].optarg then
					pos = pos+1
					if pos <= #arg then
						v.optarg = arg[pos]
					end
				end
				--print(v)
				table.insert(ret, v)
			end
			pos = pos + 1
		else
			pos = pos + 1
		end
	end
	return ret
end

-- パスからディレクトリパスを取り出し
-- @param path パス
-- @return ディレクトリパス
StringUtil.dirname = function(path)
	local delimiter = "\\"
	if string.find(path, "/", 1, true) ~= nil then
		delimiter = "/"
	end
	local path_list = StringUtil.split(path, delimiter)
	path_list[#path_list] = nil
	local ret = StringUtil.flatten(path_list, delimiter)
	if #ret == 0 then
		return ret
	else
		return ret..delimiter
	end
	
end


-- パスからファイル名を取得
-- @param path パス
-- @return ファイル名
StringUtil.basename = function(path)
	local delimiter = "\\"
	if string.find(path, "/", 1, true) ~= nil then
		delimiter = "/"
	end
	local path_list = StringUtil.split(path, delimiter)

	return path_list[#path_list]
end


-- テーブルの要素数取得
-- @param tbl テーブル
-- @return 要素数
StringUtil.getKeyCount = function(tbl)
	local ret = 0
	for k,v in pairs(tbl) do
		ret = ret + 1
	end
	return ret
end

-- 文字列がURLかを判定
-- @param str 文字列
-- @return true：URL
StringUtil.isURL = function(str)
	if str == "" then
		return false
	end

	local pos,c = string.find(str, "://")
	if pos ~= 1 and pos ~= nil then
		return true
	end
	return false
end




-- 文字列が絶対パスかを判定
-- @param 文字列
-- @return true：絶対パス
StringUtil.isAbsolutePath = function(str)
	if string.sub(str,1,1) == "/" then
		return true
	end
	if string.match(string.sub(str,1,1), '[a-zA-Z]') then
		if string.sub(str,2,2) == ":" and (string.sub(str,3,3) == "\\" or string.sub(str,3,3) == "/") then
			return true
		end
	end
	if string.sub(str,1,1) == "\\" and string.sub(str,2,2) == "\\" then
		return true
	end

  return false
end

-- URL形式の文字列からパラメータを取得
-- @param _str URL形式の文字列
-- param?key1=value1&key2=value2
-- @return パラメータを格納したテーブル
StringUtil.urlparam2map = function(_str)
	local qpos = string.find(_str, "?")
	if qpos == nil then
		qpos = 0
	else
		qpos = qpos+1
	end
	local tmp = StringUtil.split(string.sub(_str, qpos), "&")
	local retmap = {}
	for k, v in ipairs(tmp) do
		pos = string.find(v, "=")
		if pos ~= nil then
			retmap[string.sub(v,1,pos-1)] = string.sub(v, pos+1)
		else
			retmap[v] = ""
		end
	end
    return retmap
end


return StringUtil
