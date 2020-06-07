---------------------------------
--! @file ManagerConfig.lua
--! @brief マネージャのコンフィギュレーション管理クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ManagerConfig= {}
--_G["openrtm.ManagerConfig"] = ManagerConfig

local Properties = require "openrtm.Properties"
local default_config = require "openrtm.DefaultConfiguration"
local StringUtil = require "openrtm.StringUtil"


local config_file_path = {"./rtc.conf"}

-- マネージャのコンフィギュレーション管理オブジェクト初期化
-- @param argv コマンドライン引数
-- "-a"：マネージャサーバント無効
-- "-f"：設定ファイル指定
-- "-l"：ロードするモジュール指定
-- "-o"：追加のオプション指定
-- "-a"：アドレス、ポート番号指定
-- "-d"：マスターマネージャに設定
-- @return マネージャのコンフィギュレーション管理オブジェクト
ManagerConfig.new = function(argv)
	local obj = {}
	obj._configFile = ""
    obj._argprop = Properties.new()
    obj._isMaster = false

	-- コマンドライン引数により初期化
	-- @param _argv コマンドライン引数
	function obj:init(_argv)
		self:parseArgs(_argv)
	end
	-- 指定プロパティを設定
	-- @param prop プロパティ
	-- @param プロパティ
	function obj:configure(prop)
		prop:setDefaults(default_config)
		if self:findConfigFile() then
			local fd = io.open(self._configFile, "r")
			--print(fs)
			prop:load(fd)
			--print(prop)
			--print(prop)
			fd:close()
		end

		self:setSystemInformation(prop)
		if self._isMaster then
			prop:setProperty("manager.is_master","YES")
		end

		prop:mergeProperties(self._argprop)
		prop:setProperty("config_file", self._configFile)
		return prop
	end
	-- コマンドライン引数からオプション一覧取得して設定
	-- @param _argv コマンドライン引数
	function obj:parseArgs(_argv)
		local opts = StringUtil.getopt(_argv, "adlf:o:p:")
		--print(_argv)

		for i, opt in ipairs(opts) do
			--print(opt)
			--print(opt.id, opt.optarg)
			if opt.id == "a" then
				self._argprop:setProperty("manager.corba_servant", "NO")
			elseif opt.id == "f" then
				if opt.optarg ~= nil then
					self._configFile = opt.optarg
				end
			elseif opt.id == "l" then
				if opt.optarg ~= nil then
					self._configFile = opt.optarg
				end
			elseif opt.id == "o" then
				if opt.optarg ~= nil then
					local pos = string.find(opt.optarg, ":")
					if pos ~= nil then
						local idx = string.sub(opt.optarg,1,pos-1)
						local value = string.sub(opt.optarg,pos+1)
						idx = StringUtil.unescape(idx)
						idx = StringUtil.eraseHeadBlank(idx)
						idx = StringUtil.eraseTailBlank(idx)
						
						value = StringUtil.unescape(value)
						value = StringUtil.eraseHeadBlank(value)
						value = StringUtil.eraseTailBlank(value)
						--print(idx, value)
						self._argprop:setProperty(idx, value)
					end
				end
			elseif opt.id == "p" then
				if opt.optarg ~= nil then
					local arg_ = ":"..tostring(opt.optarg)
					self._argprop:setProperty("corba.endpoints", arg_)
				end
			elseif opt.id == "d" then
				self._isMaster = true
			end
		end

	end
	-- 設定ファイルの存在確認、設定
	-- @retuen true：存在しない、false：存在する
	function obj:findConfigFile()
	    if self._configFile ~= "" then
			if not self:fileExist(self._configFile) then
				return false
			end
			return true
		end
		for i,filename in ipairs(config_file_path) do
			if self:fileExist(filename) then
				self._configFile = filename
				return true
			end
		end
		return false
	end
	-- システム情報を設定する
	-- @param prop プロパティ
	function obj:setSystemInformation(prop)
	end
	-- ファイルの存在確認
	-- @retuen true：存在しない、false：存在する
	function obj:fileExist(filename)
		local fd = io.open(filename, "r")

		if fd == nil then
			return false
		else
			fd:close()
			return true
		end
	end
    if argv ~= nil then
		obj:init(argv)
	end
	return obj
end


return ManagerConfig
