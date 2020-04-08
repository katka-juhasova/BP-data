---------------------------------
--! @file ExecutionContextProfile.lua
--! @brief 実行コンテキストのプロファイル保持クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ExecutionContextProfile= {}
--_G["openrtm.ExecutionContextProfile"] = ExecutionContextProfile

local oil = require "oil"

local TimeValue = require "openrtm.TimeValue"
local NVUtil = require "openrtm.NVUtil"
local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"

local DEFAULT_PERIOD = 0.000001


local find_participant = function(comp)
	local obj = {}
	obj._comp = comp

	local call_func = function(self, comp)
		return NVUtil._is_equivalent(comp, self._comp, comp.getObjRef, self._comp.getObjRef)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end

-- 実行コンテキストのプロファイル保持オブジェクト初期化関数
-- @param kind 種別
-- @return 実行コンテキストのプロファイル保持オブジェクト
ExecutionContextProfile.new = function(kind)
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._ExecutionKind = Manager:instance():getORB().types:lookup("::RTC::ExecutionKind").labelvalue
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue

	if kind == nil then
		kind = obj._ExecutionKind.PERIODIC
	end
	obj._rtcout = Manager:instance():getLogbuf("periodic_ecprofile")
	obj._period = TimeValue.new(DEFAULT_PERIOD)
    obj._rtcout:RTC_TRACE("ExecutionContextProfile.__init__()")
    obj._rtcout:RTC_DEBUG("Actual rate: "..obj._period:sec().." [sec], "..obj._period:usec().." [usec]")
    obj._ref = oil.corba.idl.null
    obj._profile = {kind=obj._ExecutionKind.PERIODIC,
					rate=1.0/obj._period:toDouble(),
					owner=oil.corba.idl.null, participants={},
					properties={}}

	-- 実行コンテキスト終了
	function obj:exit()
		self._rtcout:RTC_TRACE("exit")
		self._profile.owner = oil.corba.idl.null
		self._profile.participants = {}
		self._profile.properties = {}
		self._ref = oil.corba.idl.null
	end
	-- 実行周期設定
	-- @param rate 実行周期
	-- @return リターンコード
	-- RTC_OK：onSettingRate、onSetRateがRTC_OKを返す
	-- BAD_PARAMETER：不正な周期を指定
	function obj:setRate(rate)
		self._rtcout:RTC_TRACE("setRate("..rate..")")
		if rate <= 0.0 then
			return self._ReturnCode_t.BAD_PARAMETER
		end
		self._profile.rate = rate
		self._period = TimeValue.new(1.0 / rate)
		return self._ReturnCode_t.RTC_OK
	end
	-- プロパティ設定
	-- @param props プロパティ
	function obj:setProperties(props)
		self._rtcout:RTC_TRACE("setProperties()")
		self._rtcout:RTC_DEBUG(props)
		NVUtil.copyFromProperties(self._profile.properties, props)
	end
	-- オブジェクトリファレンス設定
	-- @param ec_ptr オブジェクトリファレンス
	function obj:setObjRef(ec_ptr)
		self._rtcout:RTC_TRACE("setObjRef()")
		self._ref = ec_ptr
	end
	-- オブジェクトリファレンス取得
	-- @return オブジェクトリファレンス
	function obj:getObjRef()
		self._rtcout:RTC_TRACE("getObjRef()")
		return self._ref
	end
	-- 種別設定
	-- @param kind 種別
	-- @return リターンコード
	-- RTC_OK：正常に設定
    -- BAD_PARAMETER：RTC::ExecutionKindに定義のない値
	function obj:setKind(kind)
		if kind < self._ExecutionKind.PERIODIC or kind > self._ExecutionKind.OTHER then
			self._rtcout:RTC_ERROR("Invalid kind is given. "..kind)
			return self._ReturnCode_t.BAD_PARAMETER
		end

		self._rtcout:RTC_TRACE("setKind("..self:getKindString(kind)..")")
		--print(self:getKindString(kind))
		self._profile.kind = kind
		return self._ReturnCode_t.RTC_OK
	end
	function obj:getKind()
		self._rtcout:RTC_TRACE("%s = getKind()", self:getKindString(self._profile.kind))
    	return self._profile.kind
	end
	-- 実行コンテキストの種別を文字列に変換
	-- @param kind 種別
	-- @return 文字列に変換した種別
	function obj:getKindString(kind)
		local kinds_ = {"PERIODIC", "EVENT_DRIVEN", "OTHER"}
		local kind_ = kind
		if kind_ == nil then
			kind_ = self._profile.kind
		else
			kind_ = kind
		end

		if kind_ < self._ExecutionKind.PERIODIC or kind_ > self._ExecutionKind.OTHER then
			return ""
		end

		return kinds_[kind_+1]
	end
	-- 実行周期取得
	-- @return 実行周期(Hz)
	function obj:getRate()
		return self._profile.rate
	end
	-- 実行周期取得
	-- @return 実行周期(秒)
	function obj:getPeriod()
		return self._period
	end
	-- プロファイル取得
	-- @return プロファイル
	function obj:getProfile()
		self._rtcout:RTC_TRACE("getProfile()")
		return self._profile
	end

	function obj:addComponent(comp)
		self._rtcout:RTC_TRACE("addComponent()")
		if comp == oil.corba.idl.null then
			self._rtcout:RTC_ERROR("A nil reference was given.")
    		return self._ReturnCode_t.BAD_PARAMETER
		end
   		local rtobj_ = comp
    	--[[
		if rtobj_ == oil.corba.idl.null then
      		self._rtcout:RTC_ERROR("Narrowing was failed.")
    		return self._ReturnCode_t.RTC_ERROR
		end
		--]]
		table.insert(self._profile.participants, rtobj_)
        
    	return self._ReturnCode_t.RTC_OK
	end


	function obj:removeComponent(comp)
		self._rtcout:RTC_TRACE("removeComponent()")
		if comp == oil.corba.idl.null then
			self._rtcout:RTC_ERROR("A nil reference was given.")
			return self._ReturnCode_t.BAD_PARAMETER
		end

		local rtobj_ = comp
		--[[
		if rtobj_== oil.corba.idl.null then
			self._rtcout:RTC_ERROR("Narrowing was failed.")
			return self._ReturnCode_t.RTC_ERROR
		end
		--]]

		
		local index_ = CORBA_SeqUtil.find(self._profile.participants,
										find_participant(rtobj_))
		if index_ < 0 then
			self._rtcout:RTC_ERROR("The given RTObject does not exist in the EC.")
			return self._ReturnCode_t.BAD_PARAMETER
		end
		table.remove(self._profile.participants, index_)
		return self._ReturnCode_t.RTC_OK
	end

	return obj
end


return ExecutionContextProfile
