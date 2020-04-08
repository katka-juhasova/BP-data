---------------------------------
--! @file ConfigAdmin.lua
--! @brief コンフィギュレーション管理クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ConfigAdmin= {}
--_G["openrtm.ConfigAdmin"] = ConfigAdmin

local Properties = require "openrtm.Properties"
local ConfigurationListener = require "openrtm.ConfigurationListener"
local ConfigurationListeners = ConfigurationListener.ConfigurationListeners
local StringUtil = require "openrtm.StringUtil"

local ConfigurationParamListenerType = ConfigurationListener.ConfigurationParamListenerType
local ConfigurationSetListenerType = ConfigurationListener.ConfigurationSetListenerType
local ConfigurationSetNameListenerType = ConfigurationListener.ConfigurationSetNameListenerType


local Config = {}
-- コンフィギュレーションパラメータ管理オブジェクト初期化
-- 変換関数には以下の関数を使用する
-- ret, value = trans(type, str)
-- @param name 名前
-- @param var 変数
-- @param def_val デフォルト値
-- @param trans 変換関数
-- @return コンフィギュレーションパラメータ管理オブジェクト
Config.new = function(name, var, def_val, trans)
	local obj = {}
	obj.name = name
    obj.default_value = def_val
    obj.string_value = ""
    obj.callback = nil
    obj._var = var
    if trans ~= nil then
		obj._trans = trans
    else
		obj._trans = StringUtil.stringTo
	end
	-- コールバック関数設定
	-- @param cbf コールバック関数
	function obj:setCallback(cbf)
		self.callback = cbf
	end
	-- パラメータ更新の通知
	-- @param key キー
	-- @param val 値
	function obj:notifyUpdate(key, val)
		self.callback(key, val)
	end
	-- パラメータの更新
	-- @param key 値
	-- @return true：更新成功・更新済み、false：更新失敗
	-- 変換関数がfalseを返した場合は更新失敗
	function obj:update(val)
		if self.string_value == val then
			return true
		end
		
		self.string_value = val


		local ret, value = self._trans(self._var._value, val)
		if ret then
			self._var._value = value
			self:notifyUpdate(self.name, val)
			return true
		end
		local ret, value = self._trans(self._var._value, self.default_value)
		self._var._value = value
		self:notifyUpdate(self.name, val)
		return false
	end


	return obj
end

-- コンフィギュレーション管理オブジェクト初期化
-- @return コンフィギュレーション管理オブジェクト
ConfigAdmin.new = function(configsets)
	local obj = {}
	obj._configsets = configsets
    obj._activeId   = "default"
    obj._active     = true
    obj._changed    = false
    obj._params     = {}
    obj._emptyconf  = Properties.new()
    obj._newConfig  = {}
    obj._listeners  = ConfigurationListeners.new()
    obj._changedParam = {}

	-- 変数をコンフィギュレーションパラメータ設定に割り当てる
	-- @param param_name パラメータ名
	-- @param var 変数
	-- @param def_val デフォルト値 
	-- @param trans 変換関数(デフォルトはstringTo関数)
	-- @return true：バインド成功、false：バインド失敗
	function obj:bindParameter(param_name, var, def_val, trans)
		if trans == nil then
			trans = StringUtil.stringTo
		end

		if param_name == "" or def_val == "" then
			return false
		end

		--print(self:isExist(param_name))
		if self:isExist(param_name) then
			return false
		end

		local ret, value = trans(var._value, def_val)
		--if type(value) == "table" then
		--	print(#value)
		--end
		var._value = value
		if not ret then
			return false
		end
		local conf_ = Config.new(param_name, var, def_val, trans)
		table.insert(self._params, conf_)
		--print(#self._params)
		conf_:setCallback(function(config_param, config_value)self:onUpdateParam(config_param, config_value) end)
		--print(self:getActiveId())
		self:update(self:getActiveId(), param_name)

		return true
	end

	-- パラメータ削除
	-- @param param_name パラメータ名
	-- @return true：削除成功、false：削除失敗
	function obj:unbindParameter(param_name)
		local ret_param = nil
		local ret_index = -1
		for find_idx, param in ipairs(self._params) do
			if param.name == param_name then
				ret_param = param
				ret_index = find_idx
			end
		end

		if ret_index == -1 then
			return false
		end

		table.remove(self._params, ret_index)


		local leaf = self._configsets:getLeaf()
		for i, v in ipairs(leaf) do
			if v:hasKey(param_name) then
				v:removeNode(param_name)
			end
		end

		return true
	end

	-- コンフィギュレーションセットの存在確認
	-- @param config_id コンフィギュレーションセットID
	-- @return true：存在する、false：存在する
	function obj:haveConfig(config_id)
		if self._configsets:hasKey(config_id) == nil then
			return false
		else
			return true
		end
	end
	-- コンフィギュレーションセットのアクティブ化
	-- "_"から始まるIDは指定できない
	-- @param config_id コンフィギュレーションセットID
	-- @return true：アクティブ化成功、false：アクティブ化失敗
	function obj:activateConfigurationSet(config_id)
		if config_id == "" then
			return false
		end
		if string.sub(config_id,1,1) == '_' then
			return false
		end
		if not self._configsets:hasKey(config_id) then
			return false
		end
		self._activeId = config_id
		self._active   = true
		self._changed  = true
		self:onActivateSet(config_id)
		return true
	end
	-- コンフィギュレーションセットアクティブ化時のコールバック呼び出し
	-- @param config_id コンフィギュレーションセットID
	function obj:onActivateSet(config_id)
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_ACTIVATE_CONFIG_SET]:notify(config_id)
	end
	-- コンフィギュレーションパラメータ更新
	-- ID指定の場合は、指定IDのコンフィギュレーションセットの更新
	-- パラメータ、ID指定の場合は、指定パラメータの更新
	-- パラメータ、ID未指定の場合は、現在アクティブなコンフィギュレーションセット更新
	-- @param config_set コンフィギュレーションセットID
	-- @param config_param パラメータ名
	function obj:update(config_set, config_param)

		if config_set ~= nil and config_param == nil then
			if self._configsets:hasKey(config_set) == false then
				return
			end
			self._changedParam = {}
			local prop = self._configsets:getNode(config_set)
			for i, param in ipairs(self._params) do
				if prop:hasKey(param.name) then
					--print(type(param.name))
					--print(prop:getProperty(param.name))
					param:update(prop:getProperty(param.name))
				end
			end
			self:onUpdate(config_set)
		end


		if config_set ~= nil and config_param ~= nil then
			self._changedParam = {}
			local key = config_set
			key = key.."."..config_param
			for i, conf in ipairs(self._params) do
				--print(conf.name, config_param)
				if conf.name == config_param then
					--print(self._configsets:getProperty(key))
					conf:update(self._configsets:getProperty(key))
				end
			end
		end

		if config_set == nil and config_param == nil then
			self._changedParam = {}
			if self._changed and self._active then
				self:update(self._activeId)
				self._changed = false
			end
		end

    end

	-- パラメータの存在確認
	-- @param param_name パラメータ名
	-- @return true：存在する、false：存在しない
	function obj:isExist(param_name)
		if #self._params == 0 then
			return false
		end

		for i, conf in ipairs(self._params) do
			if conf.name == param_name then
				return true
			end
		end

		return false
	end

	-- コンフィギュレーションパラメータに変更があったかの確認
	-- @return true：変更あり、false：変更なし
	function obj:isChanged()
		return self._changed
	end

	-- 変更のあったコンフィギュレーションパラメータを取得
	-- 更新したコンフィギュレーションパラメータは
	-- @return 変更のあったコンフィギュレーションパラメータ一覧
	function obj:changedParameters()
		return self._changedParam
	end

	-- アクティブなコンフィギュレーションセットID取得
	-- @return アクティブなコンフィギュレーションセットID
	function obj:getActiveId()
		return self._activeId
	end




	-- コンフィギュレーション管理オブジェクトがアクティブかを確認
	-- return true：アクティブ、false：非アクティブ
	function obj:isActive()
		return self._active
	end

	-- コンフィギュレーションセット一覧取得
	-- return コンフィギュレーションセット一覧
	function obj:getConfigurationSets()
		return self._configsets:getLeaf()
	end

	-- コンフィギュレーションセット取得
	-- @param config_id コンフィギュレーションセットID
	-- @return コンフィギュレーションセット
	function obj:getConfigurationSet(config_id)

		local prop = self._configsets:findNode(config_id)
		if prop == nil then
			return self._emptyconf
		end
		return prop
	end

	-- コンフィギュレーションセットの設定
	-- 指定コンフィギュレーションセットがない場合に、新規にノードは生成しない
	-- @param config_set コンフィギュレーションセット
	-- @return true：設定成功、false：設定失敗
	function obj:setConfigurationSetValues(config_set)
		local node_ = config_set:getName()
		if node_ == "" or node_ == nil then
			return false
		end

		if not self._configsets:hasKey(node_) then
			return false
		end

		local p = self._configsets:getNode(node_)


		p:mergeProperties(config_set)
		self._changed = true
		self._active  = false
		self:onSetConfigurationSet(config_set)
		return true
	end

	-- アクティブなコンフィギュレーションセット取得
	-- @return アクティブなコンフィギュレーションセット
	function obj:getActiveConfigurationSet()
		local p = self._configsets:getNode(self._activeId)


		return p
	end

	-- コンフィギュレーションセット追加
	-- 指定コンフィギュレーションセットがない場合に、新規にノードを生成する
	-- @param configset コンフィギュレーションセット
	-- @return true：追加成功、false：追加失敗
	function obj:addConfigurationSet(configset)
		if self._configsets:hasKey(configset:getName()) then
			return false
		end
		local node = configset:getName()


		self._configsets:createNode(node)

		local p = self._configsets:getNode(node)


		p:mergeProperties(configset)
		table.insert(self._newConfig, node)

		self._changed = true
		self._active  = false
		self:onAddConfigurationSet(configset)
		return true
	end

	-- コンフィギュレーションセット削除
	-- @param config_id コンフィギュレーションセットID
	-- @return true：削除成功、false：削除失敗
	function obj:removeConfigurationSet(config_id)
		if config_id == "default" then
			return false
		end
		if self._activeId == config_id then
			return false
		end

		local find_flg = false

		local ret_idx = -1
		for idx, conf in ipairs(self._newConfig) do
			if conf == config_id then
				ret_idx = idx
				break
			end
		end


		if ret_idx == -1 then
			return false
		end

		local p = self._configsets:getNode(config_id)
		if p ~= nil then
			p:getRoot():removeNode(config_id)
		end

		table.remove(self._newConfig, ret_idx)



		self._changed = true
		self._active  = false
		self:onRemoveConfigurationSet(config_id)
		return true
	end



	-- コンフィギュレーション更新時コールバック設定
	-- @param cb コンフィギュレーションコールバック
	function obj:setOnUpdate(cb)
		print("setOnUpdate function is obsolete.")
		print("Use addConfigurationSetNameListener instead.")
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_UPDATE_CONFIG_SET]:addListener(cb, false)
    end

	-- コンフィギュレーションパラメータ更新時コールバック設定
	-- @param cb コンフィギュレーションパラメータコールバック
	function obj:setOnUpdateParam(cb)
		print("setOnUpdateParam function is obsolete.")
		print("Use addConfigurationParamListener instead.")
		self._listeners.configparam_[ConfigurationParamListenerType.ON_UPDATE_CONFIG_PARAM]:addListener(cb, false)
    end

	-- コンフィギュレーションセット設定時コールバック設定
	-- @param cb コンフィギュレーションセット設定時コールバック
	function obj:setOnSetConfigurationSet(cb)
		print("setOnSetConfigurationSet function is obsolete.")
		print("Use addConfigurationSetListener instead.")
		self._listeners.configset_[ConfigurationSetListenerType.ON_SET_CONFIG_SET]:addListener(cb, false)
    end

	-- コンフィギュレーションセット追加時コールバック設定
	-- @param cb コンフィギュレーションセット追加時コールバック
	function obj:setOnAddConfigurationSet(cb)
		print("setOnAddConfigurationSet function is obsolete.")
		print("Use addConfigurationSetListener instead.")
		self._listeners.configset_[ConfigurationSetListenerType.ON_ADD_CONFIG_SET]:addListener(cb, false)
    end

	-- コンフィギュレーションセット削除時コールバック設定
	-- @param cb コンフィギュレーションセット削除時コールバック
	function obj:setOnRemoveConfigurationSet(cb)
		print("setOnRemoveConfigurationSet function is obsolete.")
		print("Use addConfigurationSetNameListener instead.")
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_REMOVE_CONFIG_SET]:addListener(cb, False)
    end

	-- アクティブなコンフィギュレーションセット設定時コールバック設定
	-- @param cb アクティブなコンフィギュレーションセット設定時コールバック	
	function obj:setOnActivateSet(cb)
		print("setOnActivateSet function is obsolete.")
		print("Use addConfigurationSetNameListener instead.")
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_ACTIVATE_CONFIG_SET]:addListener(cb, false)
    end

	-- コンフィギュレーションパラメータコールバック設定
	-- @param _type コールバックの種別
	-- @param listener コンフィギュレーションパラメータコールバック
	-- @param autoclean 自動削除フラグ
	function obj:addConfigurationParamListener(_type, listener, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		self._listeners.configparam_[_type]:addListener(listener, autoclean)
    end

	-- コンフィギュレーションパラメータコールバック削除
	-- @param _type コールバックの種別
	-- @param listener コンフィギュレーションパラメータコールバック
	function obj:removeConfigurationParamListener(_type, listener)
		self._listeners.configparam_[_type]:removeListener(listener)
    end

	-- コンフィギュレーションセットコールバック設定
	-- @param _type コールバックの種別
	-- @param listener コンフィギュレーションセットコールバック
	-- @param autoclean 自動削除フラグ
	function obj:addConfigurationSetListener(_type, listener, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		self._listeners.configset_[_type]:addListener(listener, autoclean)
    end

	-- コンフィギュレーションセットコールバック削除
	-- @param _type コールバックの種別
	-- @param listener コンフィギュレーションセットコールバック
	function obj:removeConfigurationSetListener(_type, listener)
		self._listeners.configset_[_type]:removeListener(listener)
    end

	-- コンフィギュレーションセット名のコールバック設定
	-- @param _type コールバックの種別
	-- @param listener コンフィギュレーションセット名のコールバック設定
	-- @param autoclean 自動削除フラグ
	function obj:addConfigurationSetNameListener(_type, listener, autoclean)
		if autoclean == nil then
			autoclean = true
		end
		self._listeners.configsetname_[_type]:addListener(listener, autoclean)
    end

	-- コンフィギュレーションセット名のコールバック削除
	-- @param _type コールバックの種別
	-- @param listener コンフィギュレーションセット名のコールバック
	function obj:removeConfigurationSetNameListener(_type, listener)
		self._listeners.configsetname_[_type]:removeListener(listener)
    end

	-- コンフィギュレーション更新時コールバック呼び出し
	-- @param config_set コンフィギュレーションセット
	function obj:onUpdate(config_set)
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_UPDATE_CONFIG_SET]:notify(config_set)
    end

	-- コンフィギュレーションパラメータ更新時コールバック呼び出し
	-- @param config_param パラメータ名
	-- @param config_value 値
	function obj:onUpdateParam(config_param, config_value)
		table.insert(self._changedParam, config_param)
		self._listeners.configparam_[ConfigurationParamListenerType.ON_UPDATE_CONFIG_PARAM]:notify(config_param, config_value)
    end

	-- コンフィギュレーション設定時コールバック呼び出し
	-- @param config_set コンフィギュレーションセット
	function obj:onSetConfigurationSet(config_set)
		self._listeners.configset_[ConfigurationSetListenerType.ON_SET_CONFIG_SET]:notify(config_set)
    end

	-- コンフィギュレーション追加時コールバック呼び出し
	-- @param config_set コンフィギュレーションセット
	function obj:onAddConfigurationSet(config_set)
		self._listeners.configset_[ConfigurationSetListenerType.ON_ADD_CONFIG_SET]:notify(config_set)
    end
    -- コンフィギュレーション削除時コールバック呼び出し
	-- @param config_id コンフィギュレーションセットID
	function obj:onRemoveConfigurationSet(config_id)
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_REMOVE_CONFIG_SET]:notify(config_id)
    end

	-- コンフィギュレーションアクティブ化時コールバック呼び出し
	-- @param config_id コンフィギュレーションセットID
	function obj:onActivateSet(config_id)
		self._listeners.configsetname_[ConfigurationSetNameListenerType.ON_ACTIVATE_CONFIG_SET]:notify(config_id)
    end


	
	return obj
end


return ConfigAdmin
