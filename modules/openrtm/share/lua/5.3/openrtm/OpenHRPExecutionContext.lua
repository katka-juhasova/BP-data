---------------------------------
--! @file OpenHRPExecutionContext.lua
--! @brief トリガ駆動実行コンテキスト定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local OpenHRPExecutionContext= {}
--_G["openrtm.OpenHRPExecutionContext"] = OpenHRPExecutionContext

local ExecutionContextBase = require "openrtm.ExecutionContextBase"

local ExecutionContextBase = require "openrtm.ExecutionContextBase"
local ExecutionContextFactory = ExecutionContextBase.ExecutionContextFactory
local ECFactory = require "openrtm.ECFactory"
local oil = require "oil"

local RTCUtil = require "openrtm.RTCUtil"
local Timer = require "openrtm.Timer"

local DEFAULT_PERIOD = 0.000001


-- トリガ駆動実行コンテキスト初期化
-- @return OpenHRPExecutionContext
OpenHRPExecutionContext.new = function()
	local obj = {}
	setmetatable(obj, {__index=ExecutionContextBase.new("exttrig_sync_ec")})
	local Manager = require "openrtm.Manager"
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
	obj._ExecutionKind = Manager:instance():getORB().types:lookup("::RTC::ExecutionKind").labelvalue
	obj._rtcout = Manager:instance():getLogbuf("rtobject.exttrig_sync_ec")
	obj._rtcout:RTC_TRACE("OpenHRPExecutionContext.__init__()")

	obj._svr = Manager:instance():getORB():newservant(obj, nil, "IDL:openrtm.aist.go.jp/OpenRTM/ExtTrigExecutionContextService:1.0")
	local ref = RTCUtil.getReference(Manager:instance():getORB(), obj._svr, "IDL:openrtm.aist.go.jp/OpenRTM/ExtTrigExecutionContextService:1.0")

	obj:setObjRef(ref)
    obj:setKind(obj._ExecutionKind.PERIODIC)
    obj:setRate(1.0 / DEFAULT_PERIOD)

	obj._count  = 0

	-- RTC処理実行関数
	function obj:tick()
		self._rtcout:RTC_TRACE("tick()")
		if not self:isRunning() then
			return
		end
		self:invokeWorkerPreDo()
		local t0_ = os.clock()
		self:invokeWorkerDo()
		local t1_ = os.clock()
		self:invokeWorkerPostDo()
		local t2_ = os.clock()

		local period_ = self:getPeriod()


		if self._count > 1000 then
			
			local excdotm = t1_ - t0_
			local excpdotm = t2_ - t1_
			local slptm_ = period_:toDouble() - (t2_ - t0_)
			self._rtcout:RTC_PARANOID("Period:      "..period_:toDouble().." [s]")
			self._rtcout:RTC_PARANOID("Exec-Do:     "..excdotm.." [s]")
			self._rtcout:RTC_PARANOID("Exec-PostDo: "..excpdotm.." [s]")
			self._rtcout:RTC_PARANOID("Sleep:       "..slptm_.." [s]")
		end
		local t3_ = os.clock()
		if period_:toDouble() > (t2_ - t0_) then
			--[[
			if self._count > 1000 then
				self._rtcout:RTC_PARANOID("sleeping...")
				local slptm_ = period_:toDouble() - (t2_ - t0_)
				--oil.tasks:suspend(slptm_)
				Timer.sleep(slptm_)
			end
			]]
		end

		if self._count > 1000 then
			local t4_ = os.clock()
			self._rtcout:RTC_PARANOID("Slept:     "..(t4_ - t3_).." [s]")
			self._count = 0
		end
		self._count = self._count + 1
	end

	return obj
end

-- OpenHRPExecutionContext生成ファクトリ登録関数
OpenHRPExecutionContext.Init = function(manager)
	ExecutionContextFactory:instance():addFactory("OpenHRPExecutionContext",
		OpenHRPExecutionContext.new,
		ECFactory.ECDelete)
	ExecutionContextFactory:instance():addFactory("SynchExtTriggerEC",
		OpenHRPExecutionContext.new,
		ECFactory.ECDelete)
end


return OpenHRPExecutionContext
