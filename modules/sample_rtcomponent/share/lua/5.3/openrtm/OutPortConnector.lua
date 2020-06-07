---------------------------------
--! @file OutPortConnectorBase.lua
--! @brief OutPortコネクタ基底クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OutPortConnector= {}
--_G["openrtm.OutPortConnector"] = OutPortConnector

local ConnectorBase = require "openrtm.ConnectorBase"

-- OutPortコネクタ基底オブジェクト初期化
-- @param info プロファイル
-- @return InPortコネクタ
OutPortConnector.new = function(info)
	local obj = {}
	setmetatable(obj, {__index=ConnectorBase.new()})
	local Manager = require "openrtm.Manager"
	obj._rtcout = Manager:instance():getLogbuf("OutPortConnector")
	--print(obj._rtcout)
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
    obj._profile = info
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
	-- プロファイル設定
	-- @param profile プロファイル
	-- @return リターンコード
	function obj:setConnectorInfo(profile)
		self._profile = profile
		return self._ReturnCode_t.RTC_OK
	end

	return obj
end


return OutPortConnector
