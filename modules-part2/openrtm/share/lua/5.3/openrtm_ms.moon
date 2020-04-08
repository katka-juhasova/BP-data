---------------------------------
--! @file openrtm_ms.moon
--! @brief MoonScript用のライブラリ
---------------------------------



openrtm = require "openrtm"


openrtm_ms = {}

for k,v in pairs openrtm
	openrtm_ms[k] = v

openrtm_ms.setTimestamp = openrtm.OutPort.setTimestamp


-- @class RTObject
-- RTC基底オブジェクト
class openrtm_ms.RTObject
	-- コンストラクタ
	-- @param manager マネージャ
	new: (manager) =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.RTObject.new(manager)
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v





-- @class InPort
-- InPort
class openrtm_ms.InPort
	-- コンストラクタ
	-- @param name ポート名
	-- @param value データ変数
	-- @param data_type データ型
	-- @param buffer バッファ
	-- @param read_block 読み込み時ブロックの設定
	-- @param write_block 書き込み時時ブロックの設定
	-- @param read_timeout 読み込み時のタイムアウト
	-- @param write_timeout 書き込み時のタイムアウト
	new: (name, value, data_type, buffer, read_block, write_block, read_timeout, write_timeout) =>
		obj = openrtm.InPort.new(name, value, data_type, buffer, read_block, write_block, read_timeout, write_timeout)
		setmetatable(self, {__index:obj})


-- @class OutPort
-- アウトポート
class openrtm_ms.OutPort
	-- コンストラクタ
	-- @param name ポート名
	-- @param value データ変数
	-- @param data_type データ型
	-- @param buffer バッファ
	new: (name, value, data_type, buffer) =>
		obj = openrtm.OutPort.new(name, value, data_type, buffer)
		setmetatable(self, {__index:obj})







-- @class CorbaPort
-- CORBAポート
class openrtm_ms.CorbaPort
	-- コンストラクタ
	-- @param name ポート名
	new: (name) =>
		obj = openrtm.CorbaPort.new(name)
		setmetatable(self, {__index:obj})

			
			
-- @class Properties
-- プロパティ
class openrtm_ms.Properties
	-- コンストラクタ
	-- @param argv argv.prop：コピー元のプロパティ、argv.key・argv.value：キーと値、argv.defaults_map：テーブル
	new: (argv) =>
		obj = openrtm.Properties.new(argv)
		setmetatable(self, {__index:obj})
			
			
-- @class CorbaConsumer
-- CORBAコンシューマオブジェクト
class openrtm_ms.CorbaConsumer
	-- コンストラクタ
	-- @param consumer CORBAコンシューマオブジェクト
	new: (consumer) =>
		obj = openrtm.CorbaConsumer.new(consumer)
		setmetatable(self, {__index:obj})



openrtm_ms.ConnectorListenerStatus = openrtm.ConnectorListener.ConnectorListenerStatus
openrtm_ms.ConnectorListenerType = openrtm.ConnectorListener.ConnectorListenerType
openrtm_ms.ConnectorDataListenerType = openrtm.ConnectorListener.ConnectorDataListenerType

-- @class ConnectorDataListener
-- コネクタデータリスナ
class openrtm_ms.ConnectorDataListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ConnectorListener.ConnectorDataListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v


-- @class ConnectorListener
-- コネクタリスナ
class openrtm_ms.ConnectorListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ConnectorListener.ConnectorListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v


-- @class ManagerActionListener
-- マネージャアクションリスナ
class openrtm_ms.ManagerActionListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ManagerActionListener.ManagerActionListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v


-- @class ModuleActionListener
-- モジュールアクションリスナ
class openrtm_ms.ModuleActionListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ManagerActionListener.ModuleActionListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v


-- @class RtcLifecycleActionListener
-- RTC生成、削除に関するアクションリスナ
class openrtm_ms.RtcLifecycleActionListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ManagerActionListener.RtcLifecycleActionListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v

-- @class NamingActionListener
-- ネーミングアクションリスナ
class openrtm_ms.NamingActionListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ManagerActionListener.NamingActionListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v


-- @class LocalServiceActionListener
-- ローカルサービスアクションリスナ
class openrtm_ms.LocalServiceActionListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ManagerActionListener.LocalServiceActionListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v




-- @class ConfigurationParamListener
-- コンフィギュレーションパラメータに関するリスナ
class openrtm_ms.ConfigurationParamListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ConfigurationListener.ConfigurationParamListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v


-- @class ConfigurationParamListener
-- コンフィギュレーションパラメータに関するリスナ
class openrtm_ms.ConfigurationParamListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ConfigurationListener.ConfigurationParamListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v



-- @class ConfigurationSetNameListener
-- コンフィギュレーションセットの名前変更に関するリスナ
class openrtm_ms.ConfigurationSetNameListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ConfigurationListener.ConfigurationSetNameListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v



-- @class ConfigurationSetListener
-- コンフィギュレーションセットに関するリスナ
class openrtm_ms.ConfigurationSetListener
	-- コンストラクタ
	new: () =>
		tmp = {}
		for k,v in pairs self.__index
			tmp[k] = v
		obj = openrtm.ConfigurationListener.ConfigurationSetListener.new()
		setmetatable(self, {__index:obj})
		for k,v in pairs tmp
			self[k] = v

return openrtm_ms
