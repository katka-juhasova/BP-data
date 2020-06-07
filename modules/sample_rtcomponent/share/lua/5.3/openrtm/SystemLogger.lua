---------------------------------
--! @file SystemLogger.lua
--! @brief ロガー管理クラス定義
--! SILENT ログ出力無し
--! 出力する場合は以下の8段階
--! FATAL、ERROR、WARN、INFO、DEBUG、TRACE、VERBOSE、PARANOID
--! 現状、loggingライブラリの都合で以下の5段階になっている
--! FATAL、ERROR、WARN、INFO、DEBUG
--! DEBUG、TRACE、VERBOSE、PARANOIDはDEBUGの出力になる
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local Logger= {}
--_G["openrtm.SystemLogger"] = SystemLogger

Logger.LogStream = {}
local NO_LOGGER = true

Logger.SILENT = 0
Logger.FATAL = 1
Logger.ERROR = 2
Logger.WARN = 3
Logger.INFO = 4
Logger.DEBUG = 5
Logger.TRACE = 6
Logger.VERBOSE = 7
Logger.PARANOID = 8

-- 文字列をログレベルに変換
-- @oaram lv 文字列
-- @return ログレベル
Logger.strToLogLevel = function(lv)
    if lv == "SILENT" then
		return Logger.SILENT
    elseif lv == "FATAL" then
		return Logger.FATAL
    elseif lv == "ERROR" then
		return Logger.ERROR
    elseif lv == "WARN" then
		return Logger.WARN
    elseif lv == "INFO" then
		return Logger.INFO
    elseif lv == "DEBUG" then
		return Logger.DEBUG
    elseif lv == "TRACE" then
		return Logger.TRACE
    elseif lv == "VERBOSE" then
		return Logger.VERBOSE
    elseif lv == "PARANOID" then
		return Logger.PARANOID
    else
		return Logger.INFO
	end
end


Logger.printf = function(fmt)
    return fmt
end

-- ロガーストリーム初期化
-- @return ロガーストリーム
Logger.LogStream.new = function()
	local obj = {}
	obj._LogLock = false
	obj._logger_name = ""
	obj._loggerObj = {}
	obj._log_enable = true
	
	-- ロガーストリーム終了処理
	function obj:shutdown()
		for k,v in pairs(self._loggerObj) do
			v:shutdown()
		end
		self._loggerObj = {}
	end
	
	-- ロガー追加
	-- @param loggerObj ロガー
	function obj:addLogger(loggerObj)
		table.insert(self._loggerObj, loggerObj)
	end
	
	

	-- ログレベル設定
	-- @param level ログレベル(文字列) 
	function obj:setLogLevel(level)
		local lvl = Logger.strToLogLevel(level)
		for k,v in pairs(self._loggerObj) do
			v:setLogLevel(lvl)
		end
	end
	
	function obj:setLogLock(lock)
		if lock == 1 then
			self._LogLock = true
		elseif lock == 0 then
			self._LogLock = false
		end
    end
    
	function obj:enableLogLock()
		self._LogLock = true
	end
	
	function obj:disableLogLock()
		self._LogLock = false
	end
	
	-- ログ出力
	-- @param LV ログレベル
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_LOG(LV, msg, ...)
		if self._log_enable then
		--self.acquire()
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), LV, self._logger_name)
			end
      
		end
		--self.release()
	end
	
	-- ログ出力(FATAL)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_FATAL(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.FATAL, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(ERROR)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_ERROR(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.ERROR, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(WARN)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_WARN(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.WARN, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(INFO)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_INFO(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.INFO, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(DEBUG)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_DEBUG(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.DEBUG, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(TRACE)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_TRACE(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.TRACE, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(VERBOSE)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_VERBOSE(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.VERBOSE, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- ログ出力(PARANOID)
	-- @param msg 出力フォーマット
	-- @param ... 値
	function obj:RTC_PARANOID(msg, ...)
		--self.acquire()
		if self._log_enable then
			msg = tostring(msg)
			for k,v in pairs(self._loggerObj) do
				v:log(msg:format(...), Logger.PARANOID, self._logger_name)
			end
		end
		--self.release()
	end
	
	-- 指定名のロガー取得
	-- @param name ロガー名
	-- @return ロガー
	function obj:getLogger(name)
		local syslogger = {}
		for k,v in pairs(self) do
			syslogger[k] = v
		end
		syslogger._logger_name = name
		return syslogger
	end



	return obj
end




return Logger
