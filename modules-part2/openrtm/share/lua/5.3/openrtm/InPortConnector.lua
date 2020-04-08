---------------------------------
--! @file InPortConnectorBase.lua
--! @brief InPortコネクタ基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local InPortConnector= {}
--_G["openrtm.InPortConnectorBase"] = InPortConnector

local ConnectorBase = require "openrtm.ConnectorBase"

InPortConnector = {}

-- InPortコネクタ基底オブジェクト初期化
-- @param info プロファイル
-- @param buffer バッファ
-- @return InPortコネクタ
InPortConnector.new = function(info, buffer)
	local obj = {}
	setmetatable(obj, {__index=ConnectorBase.new()})
	local Manager = require "openrtm.Manager"
	obj._rtcout = Manager:instance():getLogbuf("InPortConnector")
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
    obj._profile = info
    obj._buffer = buffer
    obj._dataType = nil
    obj._endian = true
    -- プロファイル取得
    -- @return プロファイル
	function obj:profile()
		self._rtcout:RTC_TRACE("profile()")
		return self._profile
	end
	-- コネクタID取得
	-- @return コネクタID
	function obj:id()
		self._rtcout:RTC_TRACE("id() = "..self:profile().id)
		return self:profile().id
	end
	-- コネクタ名取得
	-- @return コネクタ名
	function obj:name()
		self._rtcout:RTC_TRACE("name() = "..self:profile().name)
		return self:profile().name
	end
	-- コネクタ切断
	-- @return リターンコード
	function obj:disconnect()
		return DataPortStatus.PORT_OK
	end
	-- バッファ取得
	-- @return バッファ
	function obj:getBuffer()
		return self._buffer
	end
	-- データ読み込み
	-- @param data data._data：データ格納オブジェクト
	-- @return リターンコード
	function obj:read(data)
		return DataPortStatus.PORT_ERROR
	end
	-- プロファイル設定
	-- @param profile プロファイル
	-- @return リターンコード
	function obj:setConnectorInfo(profile)
		self._profile = profile
		return self._ReturnCode_t.RTC_OK
	end
	-- データ型設定
	-- @param data データ型
	function obj:setDataType(data)
		self._dataType = data
		--print(self._dataType)
	end
	return obj
end


return InPortConnector
