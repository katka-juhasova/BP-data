---------------------------------
--! @file LogstreamFile.lua
--! @brief ファイル出力ロガーストリーム定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local LogstreamBase = require "openrtm.LogstreamBase"
local LogstreamFactory = LogstreamBase.LogstreamFactory
local Factory = require "openrtm.Factory"
local StringUtil = require "openrtm.StringUtil"
local Logger = require "openrtm.SystemLogger"



local LogstreamFile= {}
-- LogstreamFile.s_logger = nil
--_G["openrtm.LogstreamFile"] = LogstreamFile

-- ファイル出力ロガーストリームオブジェクト初期化
-- @return 
LogstreamFile.new = function()
	local obj = {}
	setmetatable(obj, {__index=LogstreamBase.new()})
	obj.handlers = {}
	
	-- 初期化時にプロパティを設定
	-- @param prop プロパティ
	-- 「file_name」の要素にファイル名
	-- 「,」で区切る
	-- 「stdout」に設定した場合は標準出力
	-- @return true：設定成功、false：設定失敗
	-- 登録したロガーの数が0の場合はfalse
	function obj:init(prop)
		--self.logger = require"logging.console"
		--if LogstreamFile.s_logger == nil then
		--	LogstreamFile.s_logger = self
		--end
		
		
		local files = StringUtil.split(prop:getProperty("file_name"), ",")
		for k,v in pairs(files) do
			self:addHandler(StringUtil.eraseBothEndsBlank(v))
		end
		
		
		if StringUtil.getKeyCount(self.handlers) == 0 then
			return false
		end
		
		return true
	end
	
	-- ロガーの登録
	-- @param f ファイル名
	-- 「stdout」の場合は標準出力
	-- @return true：登録成功、false：登録失敗
	-- 既に登録済みの場合はfalse
	-- 空文字列の場合はfalse
	function obj:addHandler(f)
		f = StringUtil.eraseBothEndsBlank(f)
		for k,v in pairs(self.handlers) do
			if k == f then
				return false
			end
		end
		local fname = StringUtil.normalize(f)
		if fname == "" then
			return false
		end
		
		if fname == "stdout" then
			require "logging.console"
			self.handlers[fname] = logging.console()
			return true
		else
			require "logging.file"
			self.handlers[fname] = logging.file(fname)
			return true
		end
	end
	-- ログ出力
	-- @param msg 出力文字列
	-- @param level ログレベル
	-- @param name ロガー名
	-- @return true：出力成功、false：出力失敗
	-- 設定できないログレベルの場合はfalse
	function obj:log(msg, level, name)
		if level == Logger.FATAL then
			for k,v in pairs(self.handlers) do
				v:fatal(name..msg)
			end
		elseif level == Logger.ERROR then
			for k,v in pairs(self.handlers) do
				v:error(name.." "..msg)
			end
		elseif level == Logger.WARN then
			for k,v in pairs(self.handlers) do
				v:warn(name.." "..msg)
			end
		elseif level == Logger.INFO then
			for k,v in pairs(self.handlers) do
				v:info(name.." "..msg)
			end
		elseif level == Logger.DEBUG then
			for k,v in pairs(self.handlers) do
				v:debug(name.." "..msg)
			end
		elseif level == Logger.TRACE then
			for k,v in pairs(self.handlers) do
				v:debug(name.." "..msg)
			end
		elseif level == Logger.VERBOSE then
			for k,v in pairs(self.handlers) do
				v:debug(name.." "..msg)
			end
		elseif level == Logger.PARANOID then
			for k,v in pairs(self.handlers) do
				v:debug(name.." "..msg)
			end
		else
			return false
		end
		return true
	end
	
	-- ログレベル設定
	-- @param level ログレベル
	function obj:setLogLevel(level)
		if level == Logger.INFO then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.INFO)
			end
		elseif level == Logger.FATAL then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.FATAL)
			end
		elseif level == Logger.ERROR then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.ERROR)
			end
		elseif level == Logger.WARN then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.WARN)
			end
		elseif level == Logger.DEBUG then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.DEBUG)
			end
		elseif level == Logger.SILENT then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.DEBUG)
			end
		elseif level == Logger.TRACE then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.DEBUG)
			end
		elseif level == Logger.VERBOSE then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.DEBUG)
			end
		elseif level == Logger.PARANOID then
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.DEBUG)
			end
		else
			for k,v in pairs(self.handlers) do
				v:setLevel(logging.INFO)
			end
		end
	end
	
	-- ロガー終了
	-- @return true；成功、false：失敗
	function obj:shutdown()
		self.handlers = {}
		return true
	end
	
	--function obj:getLogger(name)
	--	if name ~= nil then
	--		logging.getLogger("file."+name)
	--	else
	--		logging.getLogger("file."+name)
	--	end
	--end
	
	
	return obj
end


-- ファイル出力ロガー生成ファクトリ登録
LogstreamFile.Init = function()
	LogstreamFactory:instance():addFactory("file",
		LogstreamFile.new,
		Factory.Delete)
end



return LogstreamFile
