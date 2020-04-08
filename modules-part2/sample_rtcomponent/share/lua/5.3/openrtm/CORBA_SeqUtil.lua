---------------------------------
--! @file CORBA_SeqUtil.lua
--! @brief 配列操作ヘルプ関数
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local CORBA_SeqUtil= {}
--_G["openrtm.CORBA_SeqUtil"] = CORBA_SeqUtil

-- 指定関数がtrueになる要素を配列から検索
-- 指定関数をすべての要素に実行して判定する
-- @param seq 配列
-- @param f 関数
-- @return 配列の要素インデックス
CORBA_SeqUtil.find = function(seq, f)
	for i, s in ipairs(seq) do
		--print(f(s))
		if f(s) then
			return i
		end
	end
	return -1
end

-- オブジェクトリファレンスをIOR文字列に変換
-- 未実装
-- @param objlist オブジェクトリファレンスのリスト
-- @return IRO文字列のリスト
CORBA_SeqUtil.refToVstring = function(objlist)
	local iorlist = {}
	local Manager = require "openrtm.Manager"
	--local orb = Manager:instance():getORB()
	for i, obj in ipairs(objlist) do
		table.insert(iorlist, obj)
	end
	return iorlist
end

-- 指定関数がtrueになる場合に配列から要素を削除する
-- @param seq 配列
-- @param f 関数
CORBA_SeqUtil.erase_if = function(seq, f)
	local index = CORBA_SeqUtil.find(seq, f)
	if index < 0 then
		return
	end
	table.remove(seq ,index)
end

-- 配列を連結する
-- @param seq1 連結先の配列
-- @param seq2 後ろに連結する配列
CORBA_SeqUtil.push_back_list = function(seq1, seq2)
	for i, elem in ipairs(seq2) do
		table.insert(seq1, elem)
	end
end

-- 指定関数を配列の要素全てに実行する
-- @param seq 配列
-- @param f 関数
CORBA_SeqUtil.for_each = function(seq, f)
	for i, s in ipairs(seq) do
		f(s)
	end
end





return CORBA_SeqUtil
