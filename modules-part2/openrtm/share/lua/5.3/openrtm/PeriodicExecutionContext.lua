---------------------------------
--! @file PeriodicExecutionContext.lua
--! @brief 周期実行コンテキスト定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local PeriodicExecutionContext= {}
--_G["openrtm.PeriodicExecutionContext"] = PeriodicExecutionContext

local DEFAULT_PERIOD = 0.000001


local ExecutionContextBase = require "openrtm.ExecutionContextBase"

local ExecutionContextBase = require "openrtm.ExecutionContextBase"
local ExecutionContextFactory = ExecutionContextBase.ExecutionContextFactory
local ECFactory = require "openrtm.ECFactory"
local Task = require "openrtm.Task"
local oil = require "oil"

local RTCUtil = require "openrtm.RTCUtil"
local Timer = require "openrtm.Timer"




-- 周期実行コンテキスト初期化
-- @return 周期実行コンテキスト
PeriodicExecutionContext.new = function()
	local obj = {}
	setmetatable(obj, {__index=ExecutionContextBase.new("periodic_ec")})
	local Manager = require "openrtm.Manager"
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
	obj._ExecutionKind = Manager:instance():getORB().types:lookup("::RTC::ExecutionKind").labelvalue
	obj._rtcout = Manager:instance():getLogbuf("rtobject.periodic_ec")
	obj._rtcout:RTC_TRACE("PeriodicExecutionContext.__init__()")
	obj._svc = false
    obj._nowait = false

	--ref = Manager:instance():getORB():tostring(obj)
	obj._svr = Manager:instance():getORB():newservant(obj, nil, "IDL:omg.org/RTC/ExecutionContextService:1.0")
	local ref = RTCUtil.getReference(Manager:instance():getORB(), obj._svr, "IDL:omg.org/RTC/ExecutionContextService:1.0")
	--print(ref:_non_existent())
	--print(ref:start())
	--print(svr)
	obj:setObjRef(ref)
    obj:setKind(obj._ExecutionKind.PERIODIC)
    obj:setRate(1.0 / DEFAULT_PERIOD)
    obj._rtcout:RTC_DEBUG("Actual rate: "..obj._profile:getPeriod():sec().." [sec], "..obj._profile:getPeriod():usec().." [usec]")

    obj._cpu = {}

	-- コルーチンで周期実行処理
	-- @return 0：正常
	function obj:svc()
		self._rtcout:RTC_TRACE("svc()")
		local count_ = 0



		while(self:threadRunning()) do
			self:invokeWorkerPreDo()
			local t0_ = os.clock()
			self:invokeWorkerDo()
			self:invokeWorkerPostDo()
			local t1_ = os.clock()
			local period_ = self:getPeriod()
			if count_ > 1000 then
				local exctm_ = t1_ - t0_
				local slptm_ = period_:toDouble() - exctm_
				self._rtcout:RTC_PARANOID("Period:    "..period_:toDouble().." [s]")
				self._rtcout:RTC_PARANOID("Execution: "..exctm_.." [s]")
				self._rtcout:RTC_PARANOID("Sleep:     "..slptm_.." [s]")
			end


			local t2_ = os.clock()

			if not self._nowait and period_:toDouble() > (t1_ - t0_) then
				if count_ > 1000 then
					self._rtcout:RTC_PARANOID("sleeping...")
				end
				--print(period_:toDouble())
				local slptm_ = period_:toDouble() - (t1_ - t0_)
				--print(slptm_)
				--oil.tasks:suspend(slptm_)
				Timer.sleep(slptm_)
			else
				if oil.VERSION == "OiL 0.6" then
					Timer.sleep(0)
				else
					coroutine.yield(1)
				end
			end

			--oil.tasks:suspend(1)


			if count_ > 1000 then
				local t3_ = os.clock()
				self._rtcout:RTC_PARANOID("Slept:     "..(t3_ - t2_).." [s]")
				count_ = 0
			end
			count_ = count_ + 1

		end

		self._rtcout:RTC_DEBUG("Thread terminated.")
		return 0
	end

	-- コルーチンの処理開始
	-- @return 0：正常
	function obj:open()
		self._rtcout:RTC_TRACE("open()")
		Task.start(self)
		return 0
	end
	-- 開始時実行関数
	-- @return リターンコード
	function obj:onStarted()
		if not self._svc then
			self._svc = true
			self:open()
		end
		return self._ReturnCode_t.RTC_OK
	end
	-- 終了時実行関数
	-- @return リターンコード
	function obj:onStopped()
		if self._svc then
			self._svc = false
			--self:wait(0)
		end
		return self._ReturnCode_t.RTC_OK
	end
	-- コルーチンが動作しているかの確認
	-- @return true：動作中、false：停止済み
	function obj:threadRunning()
		return self._svc
	end
	return obj
end

-- 周期実行コンテキスト生成ファクトリ登録
PeriodicExecutionContext.Init = function(manager)
	ExecutionContextFactory:instance():addFactory("PeriodicExecutionContext",
		PeriodicExecutionContext.new,
		ECFactory.ECDelete)
end

return PeriodicExecutionContext
