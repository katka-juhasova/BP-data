---------------------------------
--! @file RTObjectStateMachine.lua
--! @brief RTC状態遷移マシン定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local RTObjectStateMachine= {}
--_G["openrtm.RTObjectStateMachine"] = RTObjectStateMachine


local StateMachine = require "openrtm.StateMachine"
local StateHolder = StateMachine.StateHolder
local NVUtil = require "openrtm.NVUtil"

local NUM_OF_LIFECYCLESTATE = 4

local ActionPredicate = {}

-- アクション実行関数オブジェクト初期化
-- @param object 状態遷移マシン
-- @param func アクション
-- @return 関数オブジェクト
ActionPredicate.new = function(object, func)
	local obj = {}
	obj.instance = object
	-- アクション実行関数
	-- @param self 自身のオブジェクト
	-- @param state 状態
	local call_func = function(self, state)
		func(self.instance, state)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


RTObjectStateMachine.new = function(id, comp)
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
	obj._LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue
	obj._id = id
    obj._rtobj = comp
    obj._sm = StateMachine.new(NUM_OF_LIFECYCLESTATE)
    obj._ca   = false
    obj._dfc  = false
    obj._fsm  = false
    obj._mode = false
    obj._caVar   = nil
    obj._dfcVar  = nil
    obj._fsmVar  = nil
    obj._modeVar = nil
    obj._rtObjPtr = nil


	-- RTCの設定
	-- @param comp RTC
	function obj:setComponentAction(comp)
		if comp.getObjRef == nil then
			self._caVar = comp
		else
			self._rtObjPtr = comp
			self._caVar = comp:getObjRef()
		end
	end
	-- データフローコンポーネントの設定
	-- @param comp RTC
	function obj:setDataFlowComponentAction(comp)
	end
	-- FSMコンポーネントの設定
	-- @param comp RTC
	function obj:setFsmParticipantAction(comp)
	end
	-- マルチモードコンポーネントの設定
	-- @param comp RTC
	function obj:setMultiModeComponentAction(comp)
	end


	-- 状態更新前の処理
	function obj:workerPreDo()
		return self._sm:worker_pre()
	end

	-- 状態更新時の処理
	function obj:workerDo()
		return self._sm:worker_do()
	end

	-- 状態更新後の処理
	function obj:workerPostDo()
		return self._sm:worker_post()
	end

	-- 状態の取得
	-- @return 状態
	function obj:getState()
		--print(self._sm:getState())
		return self._sm:getState()-1
	end

	-- 現在の状態が指定状態と一致するかの確認
	-- @param state 状態
	-- @return true：一致、false：不一致
	function obj:isCurrentState(state)
		--print(self:getState(),state)
		return (self:getState() == state)
	end

	-- 状態遷移マシンで保持しているRTCが一致するかの確認
	-- @param comp RTC
	-- @return true：一致、false：不一致
	function obj:isEquivalent(comp)
		--local Manager = require "openrtm.Manager"
		--orb = Manager:instance():getORB()
		--print(self._rtobj,comp)
		--print(comp:getInstanceName())
		--print(self._rtobj:getInstanceName())
		--return (orb:tostring(self._rtobj)==orb:tostring(comp))
		--print("abcde")


		--print(comp, self._rtobj)
		return NVUtil._is_equivalent(comp, self._rtobj, comp.getObjRef, self._rtobj.getObjRef)
		--return (comp:getInstanceName()==self._rtobj:getInstanceName())
	end

	-- 指定状態への移行
	-- @param state 状態
	function obj:goTo(state)
		self._sm:goTo(state+1)
    end

	-- RTCのオブジェクトリファレンス取得
	-- @return オブジェクトリファレンス
	function obj:getComponentObj()

		if self._rtObjPtr ~= nil then
			return self._rtObjPtr
		elseif self._caVar ~= nil then
			return self._caVar
		else
			return nil
		end
	end
	-- 実行コンテキスト開始時の処理実行
	function obj:onStartup()
		local comp = self:getComponentObj()
		if comp ~= nil then
			comp:on_startup(self._id)
		end
	end
	-- 実行コンテキスト停止時の処理実行
	function obj:onShutdown()
		local comp = self:getComponentObj()
		if comp ~= nil then
			comp:on_shutdown(self._id)
		end
	end
	-- アクティブ状態遷移後の処理実行
	-- @param st RTCの状態
	function obj:onActivated(st)
		local comp = self:getComponentObj()
		--print(self._caVar)
		--print("test",self._caVar)
		if comp == nil then
			return
		end
		--local ret = self._caVar:on_activated(self._id)
		--print(type(ret), type(self._ReturnCode_t.RTC_OK))
		--if ret ~= "RTC_OK" then
		--print("aaaa")
		if NVUtil.getReturnCode(comp:on_activated(self._id)) ~= self._ReturnCode_t.RTC_OK then
			--print("onActivated:ERROR")
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
		--print("OK")
    end
    -- 非アクティブ状態遷移後の処理実行
	-- @param st RTCの状態
	function obj:onDeactivated(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		comp:on_deactivated(self._id)
    end
    -- エラー状態遷移時の処理実行
	-- @param st RTCの状態
	function obj:onAborting(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		comp:on_aborting(self._id)
    end
    -- エラー状態の処理実行
	-- @param st RTCの状態
	function obj:onError(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		comp:on_error(self._id)
    end
    -- リセット実行時の処理実行
	-- @param st RTCの状態
	function obj:onReset(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		if NVUtil.getReturnCode(comp:on_reset(self._id)) ~= self._ReturnCode_t.RTC_OK then
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
    end
    -- アクティブ状態の処理実行
	-- @param st RTCの状態
	function obj:onExecute(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		if NVUtil.getReturnCode(comp:on_execute(self._id)) ~= self._ReturnCode_t.RTC_OK then
			--print("onExecute:ERROR")
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
    end
    -- 状態更新時の処理実行
	-- @param st RTCの状態
	function obj:onStateUpdate(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		if NVUtil.getReturnCode(comp:on_state_update(self._id)) ~= self._ReturnCode_t.RTC_OK then
			--print("onStateUpdate:ERROR")
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
    end
    -- 周期変更後の処理実行
	-- @param st RTCの状態
	-- @return リターンコード
	function obj:onRateChanged(st)
		local comp = self:getComponentObj()
		if comp == nil then
			return
		end
		local ret = comp:on_rate_changed(self._id)
		if ret ~= self._ReturnCode_t.RTC_OK then
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
		return ret
    end
    -- アクション実行
	-- @param st RTCの状態
	function obj:onAction(st)
		local comp = self:getComponentObj()
		if self._fsmVar == nil then
			return
		end
		if self._fsmVar:on_action(self._id) ~= self._ReturnCode_t.RTC_OK then
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
    end
    -- モード変更後の処理実行
	-- @param st RTCの状態
	function obj:onModeChanged(st)
		local comp = self:getComponentObj()
		if self._modeVar == nil then
			return
		end
		if self._modeVar:on_mode_changed(self._id) ~= self._ReturnCode_t.RTC_OK then
			self._sm:goTo(self._LifeCycleState.ERROR_STATE+1)
		end
	end
	
	function obj:getRTObject()
		return self._rtobj
	end

	function obj:getExecutionContextHandle()
		
		return self._id
	end

	--print(comp)
	obj:setComponentAction(comp)
	--print(obj._caVar)
    obj:setDataFlowComponentAction(comp)
    obj:setFsmParticipantAction(comp)
    obj:setMultiModeComponentAction(comp)

    obj._sm:setListener(obj)
	--print(obj.onActivated)
	--obj:onActivated(1)
    obj._sm:setEntryAction(obj._LifeCycleState.ACTIVE_STATE+1,
							ActionPredicate.new(obj, obj.onActivated))
    obj._sm:setDoAction(obj._LifeCycleState.ACTIVE_STATE+1,
							ActionPredicate.new(obj, obj.onExecute))
    obj._sm:setPostDoAction(obj._LifeCycleState.ACTIVE_STATE+1,
							ActionPredicate.new(obj, obj.onStateUpdate))
    obj._sm:setExitAction(obj._LifeCycleState.ACTIVE_STATE+1,
							ActionPredicate.new(obj, obj.onDeactivated))
    obj._sm:setEntryAction(obj._LifeCycleState.ERROR_STATE+1,
							ActionPredicate.new(obj, obj.onAborting))
    obj._sm:setDoAction(obj._LifeCycleState.ERROR_STATE+1,
							ActionPredicate.new(obj, obj.onError))
    obj._sm:setExitAction(obj._LifeCycleState.ERROR_STATE+1,
							ActionPredicate.new(obj, obj.onReset))
    local st = StateHolder.new()
    st.prev = obj._LifeCycleState.INACTIVE_STATE+1
    st.curr = obj._LifeCycleState.INACTIVE_STATE+1
    st.next = obj._LifeCycleState.INACTIVE_STATE+1
    obj._sm:setStartState(st)
    obj._sm:goTo(obj._LifeCycleState.INACTIVE_STATE+1)
	return obj
end


return RTObjectStateMachine
