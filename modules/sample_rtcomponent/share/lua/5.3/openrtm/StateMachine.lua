---------------------------------
--! @file StateMachine.lua
--! @brief 状態遷移マシン定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local StateMachine= {}
--_G["openrtm.StateMachine"] = StateMachine


local StringUtil = require "openrtm.StringUtil"


StateMachine.StateHolder = {}
-- 状態を保持するホルダオブジェクト初期化
-- @return ホルダオブジェクト
StateMachine.StateHolder.new = function()
	local obj = {}
	obj.curr = nil
	obj.prev = nil
	obj.next = nil
	return obj
end

-- 状態遷移マシン初期化
-- @param num_of_state 状態数
-- @return 状態遷移マシン
StateMachine.new = function(num_of_state)
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue

	local state_array = {obj._LifeCycleState.CREATED_STATE+1,
                 obj._LifeCycleState.INACTIVE_STATE+1,
                 obj._LifeCycleState.ACTIVE_STATE+1,
                 obj._LifeCycleState.ERROR_STATE+1}

    obj._num = num_of_state
    obj._listener = nil
    obj._entry  = {}
    obj._predo  = {}
    obj._do     = {}
    obj._postdo = {}
    obj._exit   = {}


	-- 状態遷移時アクションにnilを設定
	-- @param s アクション
	-- @param nullfunc nil
	function obj:setNullFunc(s, nullfunc)
		for i =1,self._num do
			s[state_array[i]] = nullfunc
		end
	end

	-- コールバック設定
	-- @param listener コールバック関数
	function obj:setListener(listener)
		self._listener = listener
    end
    -- entryアクションのコールバック関数を設定
    -- @param state 状態
    -- @param call_back コールバック関数
    -- @return true：設定成功
	function obj:setEntryAction(state, call_back)
		self._entry[state] = call_back
		return true
	end
	-- doアクションのコールバック関数を設定
    -- @param state 状態
    -- @param call_back コールバック関数
    -- @return true：設定成功
	function obj:setDoAction(state, call_back)
		self._do[state] = call_back
		return true
	end
	-- doアクション実行後のコールバック関数を設定
    -- @param state 状態
    -- @param call_back コールバック関数
    -- @return true：設定成功
	function obj:setPostDoAction(state, call_back)
		self._postdo[state] = call_back
		return true
	end
	function obj:setPreDoAction(state, call_back)
		self._predo[state] = call_back
		return true
	end
	-- exitアクションのコールバック関数を設定
    -- @param state 状態
    -- @param call_back コールバック関数
    -- @return true：設定成功
	function obj:setExitAction(state, call_back)
		self._exit[state] = call_back
		return true
	end
	-- 初期状態設定
	-- @param states 初期状態
	function obj:setStartState(states)
		self._states = StateMachine.StateHolder.new()
		self._states.curr = states.curr
		self._states.prev = states.prev
		self._states.next = states.next
	end
	-- 指定状態に遷移
	-- @param state 状態
	function obj:goTo(state)
		self._states.next = state
		if self._states.curr == state then
			self._selftrans = true
		end
    end
    
	-- 状態の同期処理
	-- @param states 状態
	function obj:sync(states)
		states.prev = self._states.prev
		states.curr = self._states.curr
		states.next = self._states.next
	end
	
	-- 状態遷移マシン実行前の処理
	function obj:worker_pre()
		local state = StateMachine.StateHolder.new()
		self:sync(state)
		--print(state.curr)
		--print(state.curr)
		if state.curr == state.next then
			if self._predo[state.curr] ~= nil then
				self._predo[state.curr](state)
			end
			return
		end

		if self._exit[state.curr] ~= nil then
			self._exit[state.curr](state)
		end
		--print(state.curr)
		self:sync(state)
		if state.curr ~= state.next then
			state.curr = state.next
			--print(state.curr,self._entry[state.curr])
			if self._entry[state.curr] ~= nil then
				self._entry[state.curr](state)
			end
			self:update_curr(state.curr)
		end
	end
	-- 状態遷移マシン実行前の処理
	function obj:worker_do()
		local state = StateMachine.StateHolder.new()
		self:sync(state)

		if self._do[state.curr] ~= nil then
			self._do[state.curr](state)
		end
    end
	-- 状態遷移マシン実行後の処理
	function obj:worker_post()
		local state = StateMachine.StateHolder.new()
		self:sync(state)
		if self._postdo[state.curr] ~= nil then
			self._postdo[state.curr](state)
		end
    end
    -- 状態取得
    -- @return 状態
	function obj:getState()
		return self._states.curr
	end
	-- 状態更新
	-- @param 状態
	function obj:update_curr(curr)
		self._states.curr = curr
	end


	obj:setNullFunc(obj._entry,  nil)
    obj:setNullFunc(obj._do,     nil)
    obj:setNullFunc(obj._exit,   nil)
    obj:setNullFunc(obj._predo,  nil)
    obj:setNullFunc(obj._postdo, nil)
    obj._transit = nil
    obj._selftrans = false

	return obj
end


return StateMachine
