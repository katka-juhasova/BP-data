---------------------------------
--! @file SimulatorExecutionContext.lua
--! @brief トリガ駆動実行コンテキスト定義
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local SimulatorExecutionContext= {}
--_G["openrtm.SimulatorExecutionContext"] = SimulatorExecutionContext

local ExecutionContextBase = require "openrtm.ExecutionContextBase"

local ExecutionContextBase = require "openrtm.ExecutionContextBase"
local ExecutionContextFactory = ExecutionContextBase.ExecutionContextFactory
local ECFactory = require "openrtm.ECFactory"
local oil = require "oil"

local RTCUtil = require "openrtm.RTCUtil"

local OpenHRPExecutionContext = require "openrtm.OpenHRPExecutionContext"


-- シミュレーション用コンテキスト初期化
-- @return SimulatorExecutionContext
SimulatorExecutionContext.new = function()
	local obj = {}
	setmetatable(obj, {__index=OpenHRPExecutionContext.new()})
	local Manager = require "openrtm.Manager"


	obj._svr = Manager:instance():getORB():newservant(obj, nil, "IDL:openrtm.aist.go.jp/OpenRTM/ExtTrigExecutionContextService:1.0")
	local ref = RTCUtil.getReference(Manager:instance():getORB(), obj._svr, "IDL:openrtm.aist.go.jp/OpenRTM/ExtTrigExecutionContextService:1.0")
	obj:setObjRef(ref)


	
	function obj:activate_component(comp)
		
		local rtobj = self._worker:findComponent(comp)
		
		if rtobj == nil then
			return self._ReturnCode_t.BAD_PARAMETER
		end
		
    	if not rtobj:isCurrentState(self._LifeCycleState.INACTIVE_STATE) then
			return self._ReturnCode_t.PRECONDITION_NOT_MET
		end
		
      
    	self._syncActivation = false
    	self:activateComponent(comp)
    
    	self:invokeWorkerPreDo()

		if rtobj:isCurrentState(self._LifeCycleState.ACTIVE_STATE) then
			return self._ReturnCode_t.RTC_OK
		end

    	return self._ReturnCode_t.RTC_ERROR
	end


	function obj:deactivate_component(comp)
		local rtobj = self._worker:findComponent(comp)
		if rtobj == nil then
			return self._ReturnCode_t.BAD_PARAMETER
		end
    	if not rtobj:isCurrentState(self._LifeCycleState.ACTIVE_STATE) then
			return self._ReturnCode_t.PRECONDITION_NOT_MET
		end
      
    	self._syncDeactivation = false
    	self:deactivateComponent(comp)
    
    	self:invokeWorkerPreDo()
    	self:invokeWorkerDo()
    	self:invokeWorkerPostDo()


    	if rtobj:isCurrentState(self._LifeCycleState.INACTIVE_STATE) then
			return self._ReturnCode_t.RTC_OK
		end

    	return self._ReturnCode_t.RTC_ERROR
	end


	function obj:reset_component(comp)
		local rtobj = self._worker:findComponent(comp)
		if rtobj == nil then
			return self._ReturnCode_t.BAD_PARAMETER
		end
    	if not rtobj:isCurrentState(self._LifeCycleState.ERROR_STATE) then
			return self._ReturnCode_t.PRECONDITION_NOT_MET
		end
      
    	self._syncReset = false
    	self:resetComponent(comp)
    
    	self:invokeWorkerPreDo()
    	self:invokeWorkerDo()
    	self:invokeWorkerPostDo()


    	if rtobj:isCurrentState(self._LifeCycleState.INACTIVE_STATE) then
			return self._ReturnCode_t.RTC_OK
		end

    	return self._ReturnCode_t.RTC_ERROR
	end

	return obj
end


-- SimulatorExecutionContext生成ファクトリ登録関数
SimulatorExecutionContext.Init = function(manager)
	ExecutionContextFactory:instance():addFactory("SimulatorExecutionContext",
		SimulatorExecutionContext.new,
		ECFactory.ECDelete)
end


return SimulatorExecutionContext
