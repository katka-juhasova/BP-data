---------------------------------
--! @file ModuleManager.lua
--! @brief モジュール管理マネージャ定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local StringUtil = require "openrtm.StringUtil"
local ObjectManager = require "openrtm.ObjectManager"
local Properties = require "openrtm.Properties"



local ModuleManager= {}
--_G["openrtm.ModuleManager"] = ModuleManager


local CONFIG_EXT    = "manager.modules.config_ext"
local CONFIG_PATH   = "manager.modules.config_path"
local DETECT_MOD    = "manager.modules.detect_loadable"
local MOD_LOADPTH   = "manager.modules.load_path"
local INITFUNC_SFX  = "manager.modules.init_func_suffix"
local INITFUNC_PFX  = "manager.modules.init_func_prefix"
local ALLOW_ABSPATH = "manager.modules.abs_path_allowed"
local ALLOW_URL     = "manager.modules.download_allowed"
local MOD_DWNDIR    = "manager.modules.download_dir"
local MOD_DELMOD    = "manager.modules.download_cleanup"
local MOD_PRELOAD   = "manager.modules.preload"


local DLL = {}

DLL.new = function(dll)
	local obj = {}
	obj.dll = dll
	return obj
end

-- モジュール保持オブジェクト初期化
-- @param dll モジュール
-- @param prop 設定情報
-- 「file_path」の要素にはファイルパスを格納する
-- 「import_name」の要素にはモジュール名を格納する
-- @return モジュール保持オブジェクト
local DLLEntity = {}
DLLEntity.new = function(dll,prop)
	local obj = {}
	obj.dll = dll
	obj.properties = prop
	return obj
end

-- モジュール比較関数オブジェクトの初期化
-- @param argv argv.name：ファイルパス
-- @return モジュール比較関数オブジェクト
local DLLPred = function(argv)
	local obj = {}
	if argv.name ~= nil then
		obj._import_name = argv.name
	end
	if argv.factory ~= nil then
		obj._import_name = argv.factory
	end
	-- モジュールの比較
	-- @param self 自身のオブジェクト
	-- @param dll 比較対象のモジュール
	-- ファイルパスの一致で確認
	-- @return true：一致
	local call_func = function(self, dll)
		--print(self._filepath, dll.properties:getProperty("file_path"))
		--print(self._import_name, dll.properties:getProperty("import_name"))
		return (self._import_name == dll.properties:getProperty("import_name"))
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


ModuleManager.Error = {}
-- エラー例外オブジェクトの初期化
-- @param reason_ エラー内容
-- @return エラー例外オブジェクト
ModuleManager.Error.new = function(reason_)
	local obj = {}
	obj.reason = reason_
	obj.type = "Error"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.reason
		return str
	end
	setmetatable(obj, {__tostring =str_func})
	return obj
end


ModuleManager.NotFound = {}
-- オブジェクトが存在しない例外オブジェクトの初期化
-- @param name_ エラー内容
-- @return 例外オブジェクト
ModuleManager.NotFound.new = function(name_)
	local obj = {}
	obj.name = name_
	obj.type = "NotFound"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.name
		return str
	end
	setmetatable(obj, {__tostring =str_func})
	return obj
end


ModuleManager.FileNotFound = {}
-- ファイルが存在しない例外オブジェクトの初期化
-- @param name_ エラー内容
-- @return 例外オブジェクト
ModuleManager.FileNotFound.new = function(name_)
	local obj = {}
	obj.type = "FileNotFound"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.name
		return str
	end
	setmetatable(obj, {__tostring =str_func, __index=ModuleManager.NotFound.new(name_)})
	return obj
end

ModuleManager.ModuleNotFound = {}
-- モジュールが存在しない例外オブジェクトの初期化
-- @param name_ エラー内容
-- @return 例外オブジェクト
ModuleManager.ModuleNotFound.new = function(name_)
	local obj = {}
	obj.type = "ModuleNotFound"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.name
		return str
	end
	setmetatable(obj, {__tostring =str_func, __index=ModuleManager.NotFound.new(name_)})
	return obj
end

ModuleManager.SymbolNotFound = {}
-- シンボルが存在しない例外オブジェクトの初期化
-- @param name_ エラー内容
-- @return 例外オブジェクト
ModuleManager.SymbolNotFound.new = function(name_)
	local obj = {}
	obj.type = "SymbolNotFound"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.name
		return str
	end
	setmetatable(obj, {__tostring =str_func, __index=ModuleManager.NotFound.new(name_)})
	return obj
end


ModuleManager.NotAllowedOperation = {}
-- 指定した操作ができない場合の例外オブジェクトの初期化
-- @param reason_ エラー内容
-- @return 例外オブジェクト
ModuleManager.NotAllowedOperation.new = function(reason_)
	local obj = {}
	obj.type = "NotAllowedOperation"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.reason
		return str
	end
	setmetatable(obj, {__tostring =str_func, __index=ModuleManager.Error.new(reason_)})
	return obj
end


ModuleManager.InvalidArguments = {}
-- 不正な引数指定の例外オブジェクトの初期化
-- @param reason_ エラー内容
-- @return 例外オブジェクト
ModuleManager.InvalidArguments.new = function(reason_)
	local obj = {}
	obj.type = "InvalidArguments"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.reason
		return str
	end
	setmetatable(obj, {__tostring =str_func, __index=ModuleManager.Error.new(reason_)})
	return obj
end


ModuleManager.InvalidOperation = {}
-- 不正な操作の例外オブジェクトの初期化
-- @param reason_ エラー内容
-- @return 例外オブジェクト
ModuleManager.InvalidOperation.new = function(reason_)
	local obj = {}
	obj.type = "InvalidOperation"
	local str_func = function(self)
		local str = "ModuleManager."..self.type..":"..self.reason
		return str
	end
	setmetatable(obj, {__tostring =str_func, __index=ModuleManager.Error.new(reason_)})
	return obj
end






-- モジュール管理オブジェクトの初期化
-- @param prop プロパティ
-- 「manager.modules.abs_path_allowed」がYESの時、絶対パスでファイルを指定できる
-- 「manager.modules.download_allowed」がYESの時、URLでファイルを指定できる
-- @return モジュール管理オブジェクト
ModuleManager.new = function(prop)
	local obj = {}

	-- 終了関数
	function obj:exit()
		self:unloadAll()
	end

	-- モジュールのロード
	-- @param file_name ファイルパス
	-- ファイル名のみの指定の場合は「manager.modules.load_path」で設定したパスを探査する
	-- @param init_func 初期化関数
	-- @return ファイルパス
	function obj:load(file_name, init_func)
		file_name = string.gsub(file_name, "\\", "/")
		self._rtcout:RTC_TRACE("load(fname = "..file_name..")")
		if file_name == "" then
			error(ModuleManager.InvalidArguments.new("Invalid file name."))
		end
		if StringUtil.isURL(file_name) then
			if not self._downloadAllowed then
				error(ModuleManager.NotAllowedOperation.new("Downloading module is not allowed."))
			else
				error(ModuleManager.NotFound.new("Not implemented."))
			end
		end
		local import_name = StringUtil.basename(file_name)
		local pathChanged=false
		local file_path = nil
		local save_path = ""


		if StringUtil.isAbsolutePath(file_name) then
			if not self._absoluteAllowed then
				error(ModuleManager.NotAllowedOperation.new("Absolute path is not allowed"))
			else
				save_path = package.path
				package.path = package.path..";"..StringUtil.dirname(file_name).."?.lua"

				pathChanged = true
				import_name = StringUtil.basename(file_name)
				file_path = file_name
			end

		else
			file_path = self:findFile(file_name, self._loadPath)
			if file_path == nil then
				error(ModuleManager.FileNotFound.new(file_name))
			end
		end


		
		if not self:fileExist(file_path) then

			error(ModuleManager.FileNotFound.new(file_name))
		end



		local f = io.open(file_path, "r")
		if init_func ~= nil then
			if string.find(f:read("*a"), init_func) == nil then

				error(ModuleManager.FileNotFound.new(file_name))
			end
		end
		f:close()



		if not pathChanged then
			package.path = package.path..";"..StringUtil.dirname(file_path).."?.lua"
		end

		local ext_pos = string.find(import_name, ".lua")
		if ext_pos ~= nil then
			import_name = string.sub(import_name,1,ext_pos-1)
		end

		--print(import_name)
		--print("testModule", tostring(import_name))
		local mo = require(tostring(import_name))
		--local mo = require "testModule"
		--print(mo)
		--print(package.path)

		if pathChanged then
			package.path = save_path
		end


		file_path = string.gsub(file_path, "\\", "/")
		file_path = string.gsub(file_path, "//", "/")

		--print(mo,type(mo))
		--print(file_path)
		local dll = DLLEntity.new(mo,Properties.new())

		dll.properties:setProperty("file_path",file_path)
		dll.properties:setProperty("import_name",import_name)
		self._modules:registerObject(dll)


		if init_func == nil then
			return file_name
		end

		self:symbol(import_name,init_func)(self._mgr)

		return file_name
	end

	-- 指定パス一覧にファイルが存在するかを確認
	-- @param fname ファイル名
	-- @param load_path ディレクトリパスのリスト
	-- @return ファイルが存在した場合はファイルのパスを返す
	-- 存在しない場合は空文字列を返す
	function obj:findFile(fname, load_path)
		file_name = fname

		for k, path in ipairs(load_path) do
			local f = nil
			local suffix = self._properties:getProperty("manager.modules.Lua.suffixes")
			if string.find(fname, "."..suffix) == nil then
				f = tostring(path).."/"..tostring(file_name).."."..suffix
			else
				f = tostring(path).."/"..tostring(file_name)
			end
			
			
			--print(self:fileExist(f))
			if self:fileExist(f) then
				f = string.gsub(f,"\\","/")
				f = string.gsub(f,"//","/")
				return f
			end
			--local filelist = {}
			--StringUtil.findFile(path,file_name,filelist)

			--if len(filelist) > 0 then
			--	return filelist[1]
			--end
		end
		return ""
	end

	-- ファイルの存在確認
	-- @param filename ファイル名
	-- @return true：存在する
	function obj:fileExist(filename)
		local fname = filename
		local suffix = self._properties:getProperty("manager.modules.Lua.suffixes")
		if string.find(fname, "."..suffix) == nil then
			fname = tostring(filename).."."..suffix
		end
		--print(fname)

		--if os.path.isfile(fname)
		--	return True
		--end
		--print(fname)

		local f = io.open(fname, "r")
		if f ~= nil then
			return true
		end
		return false

		--return false
	end

	-- モジュールから指定関数を取得
	-- @param import_name モジュール名
	-- 既にモジュール名のモジュールが登録済みである必要がある
	-- @param func_name 関数名
	-- @return 関数オブジェクト
	function obj:symbol(import_name, func_name)
		local dll = self._modules:find(import_name)
		--print(dll, file_name)
		if dll == nil then
			error(ModuleManager.ModuleNotFound.new(import_name))
		end

		local func = dll.dll[func_name]

		if func == nil then
			error(ModuleManager.SymbolNotFound.new(import_name))
		end

		return func
	end

	-- モジュールのアンロード
	-- @param file_name ファイルパス
	function obj:unload(file_name)
		file_name = string.gsub(file_name, "\\", "/")
		file_name = string.gsub(file_name, "//", "/")
		local dll = self._modules:find(file_name)
		if dll == nil then
			error(ModuleManager.NotFound.new(file_name))
		end
		local dll_name = dll.properties:getProperty("import_name")
		--print(package.loaded[dll_name])
		package.loaded[dll_name] = nil
		self._modules:unregisterObject(file_name)

	end

	-- 全モジュールのアンロード
	function obj:unloadAll()
		local dlls = self._modules:getObjects()
		for k,dll in ipairs(dlls) do
			local ident = dll.properties:getProperty("import_name")
			--print(ident)
			self._modules:unregisterObject(ident)
		end
	end

	-- ロード済みのモジュール全てのプロファイルを取得
	-- @return 全モジュールのプロファイル
	function obj:getLoadedModules()
		local dlls = self._modules:getObjects()
		local modules = {}
		for k,dll in ipairs(dlls) do
			table.insert(modules, dll.properties)
		end
		return modules
	end

	obj._properties = prop
	obj._configPath = StringUtil.split(prop:getProperty(CONFIG_PATH), ",")

	for k, v in pairs(obj._configPath) do
		obj._configPath[k] = StringUtil.eraseHeadBlank(v)
	end
	obj._loadPath = StringUtil.split(prop:getProperty(MOD_LOADPTH,"./"), ",")
	local system_path = StringUtil.split(package.path,";")

	for k, v in pairs(obj._loadPath) do
		obj._loadPath[k] = StringUtil.eraseHeadBlank(v)
	end

	for k, v in pairs(system_path) do
		local path = StringUtil.eraseHeadBlank(v)
		if path ~= "" then
			path = StringUtil.dirname(path)
			table.insert(obj._loadPath, path)
		end
		
	end

	obj._absoluteAllowed = StringUtil.toBool(prop:getProperty(ALLOW_ABSPATH),
							"yes", "no", false)

	obj._downloadAllowed = StringUtil.toBool(prop:getProperty(ALLOW_URL),
							"yes", "no", false)

	obj._initFuncSuffix = prop:getProperty(INITFUNC_SFX)
	obj._initFuncPrefix = prop:getProperty(INITFUNC_PFX)
	obj._modules = ObjectManager.new(DLLPred)
	obj._rtcout = nil
	local Manager = require "openrtm.Manager"
	obj._mgr = Manager:instance()
	if obj._rtcout == nil then
		obj._rtcout = obj._mgr:getLogbuf("ModuleManager")
	end

	obj._modprofs = {}
	return obj
end


return ModuleManager
