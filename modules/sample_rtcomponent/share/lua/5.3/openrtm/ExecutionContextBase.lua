---------------------------------
--! @file ExecutionContextBase.lua
--! @brief 実行コンテキスト基底クラス定義
--! 実行コンテキストを作成する場合はExecutionContextBaseをメタテーブルに設定する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ExecutionContextBase= {}
--_G["openrtm.ExecutionContextBase"] = ExecutionContextBase


local TimeValue = require "openrtm.TimeValue"
local ExecutionContextWorker = require "openrtm.ExecutionContextWorker"
local ExecutionContextProfile = require "openrtm.ExecutionContextProfile"
local GlobalFactory = require "openrtm.GlobalFactory"
local NVUtil = require "openrtm.NVUtil"
local Properties = require "openrtm.Properties"


local DEFAULT_EXECUTION_RATE = 1000

-- 実行コンテキスト基底オブジェクト初期化関数
-- @param name 名前
-- @return 実行コンテキスト
ExecutionContextBase.new = function(name)
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._ReturnCode_t = Manager:instance():getORB().types:lookup("::RTC::ReturnCode_t").labelvalue
	obj._LifeCycleState = Manager:instance():getORB().types:lookup("::RTC::LifeCycleState").labelvalue

	obj._rtcout = Manager:instance():getLogbuf("ec_base")
    obj._activationTimeout   = TimeValue.new(0.5)
    obj._degetConfigvationTimeout = TimeValue.new(0.5)
    obj._resetTimeout        = TimeValue.new(0.5)
    obj._syncActivation   = true
    obj._syncDeactivation = true
    obj._syncReset        = true
    obj._worker  = ExecutionContextWorker.new()
    obj._profile = ExecutionContextProfile.new()

    -- 初期化時に実行コンテキストにプロパティを設定する
    -- @param props プロパティ
	function obj:init(props)
		self._rtcout:RTC_TRACE("init()")
		self._rtcout:RTC_DEBUG(props)
		--print(props)
		self:setExecutionRate(props)
		self:setProperties(props)

		self._syncActivation   = false
		self._syncDeactivation = false
		self._syncReset        = false
	end
	-- 実行コンテキストを終了する
	function obj:exit()
		self._rtcout:RTC_TRACE("exit()")
		self._profile:exit()
		self._worker:exit()
	end
	-- 実行周期を設定する
	-- 「rate」の要素名から実行周期を取得する
	-- @param props プロパティ
	-- @return true：設定成功、false：設定失敗
	-- 実行周期を数値に変換できなかった場合はfalse
	function obj:setExecutionRate(props)
		if props:findNode("rate") then
			local rate_ = tonumber(props:getProperty("rate"))
			if rate_ ~= nil then
				self:setRate(rate_)
				return true
			end
		end
		return false
	end

	-- 実行周期設定
	-- @param rate 実行周期
	-- @return リターンコード
	-- RTC_OK：onSettingRate、onSetRateがRTC_OKを返す
	-- BAD_PARAMETER：不正な周期を指定
	function obj:setRate(rate)
		self._rtcout:RTC_TRACE("setRate("..rate..")")
		local ret_ = self._profile:setRate(self:onSettingRate(rate))
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Setting execution rate failed. "..rate)
			return ret_
		end

		ret_ = self._worker:rateChanged()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Invoking on_rate_changed() for each RTC failed.")
			return ret_
		end

		ret_ = self:onSetRate(rate)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onSetRate("..rate..") failed.")
			return ret_
		end
		self._rtcout:RTC_INFO("setRate("..rate..") done")
		return ret_
	end




	-- プロパティの設定
	-- @param props プロパティ
	function obj:setProperties(props)
		self._profile:setProperties(props)
	end

	-- オブジェクトリファレンス設定
	-- @param ec_ptr オブジェクトリファレンス
	function obj:setObjRef(ec_ptr)
		self._worker:setECRef(ec_ptr)
		self._profile:setObjRef(ec_ptr)
    end

    -- 実行コンテキストの種類設定
    -- @param 実行コンテキストの種類
    -- @return リターンコード
    -- RTC_OK：正常に設定
    -- BAD_PARAMETER：RTC::ExecutionKindに定義のない値
	function obj:setKind(kind)
		return self._profile:setKind(kind)
	end

	-- 実行コンテキストにRTCを関連付ける
	-- @param rtc RTC
	-- @return リターンコード
	-- RTC_OK：正常にバインド
	-- BAD_PARAMETER：RTCが不正
	-- RTC_ERROR：実行コンテキストが不正
	function obj:bindComponent(rtc)
		return self._worker:bindComponent(rtc)
	end

	-- オブジェクトリファレンス取得
	-- @return オブジェクトリファレンス
	function obj:getObjRef()
		return self._profile:getObjRef()
	end

	-- 実行コンテキストを開始する
	-- @return リターンコード
	-- RTC_OK：onStarting、onStartedがRTC_OKを返す
	-- PRECONDITION_NOT_MET：既に実行状態
	function obj:start()
		self._rtcout:RTC_TRACE("start()")
		local ret_ = self:onStarting()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onStarting() failed. Starting EC aborted.")
			return ret_
		end

		ret_ = self._worker:start()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Invoking on_startup() for each RTC failed.")
			return ret_
		end

		ret_ = self:onStarted()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onStartted() failed. Started EC aborted..")
			self._worker:stop()
			self._rtcout:RTC_ERROR("on_shutdown() was invoked, because of onStarted")
			return ret_
		end

		return ret_
	end

	-- 実行状態が変化時のコールバック
	-- @param running 実行状態
	-- @return 実行状態
	function obj:onIsRunning(running)
		return running
	end
	-- 実行コンテキスト開始時のコールバック
	-- @return リターンコード
	function obj:onStarting()
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行コンテキスト開始後のコールバック
	-- @return リターンコード
	function obj:onStarted()
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行コンテキスト停止時のコールバック
	-- @return リターンコード
	function obj:onStopping()
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行コンテキスト停止後のコールバック
	-- @return リターンコード
	function obj:onStopped()
		return self._ReturnCode_t.RTC_OK
	end
	-- 実行周期取得時のコールバック
	-- @param rate 実行周期
	-- @return 実行周期
	function obj:onGetRate(rate)
		return rate
	end
	-- 実行周期設定時のコールバック
	-- @param rate 実行周期
	-- @return 実行周期
	function obj:onSettingRate(rate)
		--print(rate)
		return rate
	end

	-- 実行周期設定後のコールバック
	-- @param rate 実行周期
	-- @return リターンコード
	function obj:onSetRate(rate)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTC追加時のコールバック
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:onAddingComponent(rtobj)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTC追加後のコールバック
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:onAddedComponent(rtobj)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTC削除時のコールバック
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:onRemovingComponent(rtobj)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTC削除後のコールバック
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:onRemovedComponent(rtobj)
		return self._ReturnCode_t.RTC_OK
	end
	-- アクティブ時のコールバック
	-- @param comp RTC
	-- @return リターンコード
	function obj:onActivating(comp)
		return self._ReturnCode_t.RTC_OK
	end
	-- アクティブ状態遷移待機後のコールバック
	-- @param comp RTC
	-- @param count 待機回数
	-- @return リターンコード
	function obj:onWaitingActivated(comp, count)
		return self._ReturnCode_t.RTC_OK
	end
	-- アクティブ状態遷移後のコールバック
	-- @param comp RTC
	-- @param count 待機回数
	-- @return リターンコード
	function obj:onActivated(comp, count)
		return self._ReturnCode_t.RTC_OK
	end
	-- アクティブ状態遷移開始時のコールバック
	-- @param comp RTC
	-- @return リターンコード
	function obj:onActivating(comp)
		return self._ReturnCode_t.RTC_OK
	end
	-- 非アクティブ状態遷移開始時のコールバック
	-- @param comp RTC
	-- @return リターンコード
	function obj:onDeactivating(comp)
		return self._ReturnCode_t.RTC_OK
	end
	-- 非アクティブ状態遷移後のコールバック
	-- @param comp RTC
	-- @param count 待機回数
	-- @return リターンコード
	function obj:onWaitingDeactivated(comp, count)
		return self._ReturnCode_t.RTC_OK
	end
	-- 非アクティブ状態遷移後のコールバック
	-- @param comp RTC
	-- @param count 待機回数
	-- @return リターンコード
	function obj:onDeactivated(comp, count)
		return self._ReturnCode_t.RTC_OK
	end
	-- リセット実行開始時のコールバック
	-- @param comp RTC
	-- @return リターンコード
	function obj:onResetting(comp)
		return self._ReturnCode_t.RTC_OK
	end
	-- リセット待機時のコールバック
	-- @param comp RTC
	-- @param count 待機回数
	-- @return リターンコード
	function obj:onWaitingReset(comp, count)
		return self._ReturnCode_t.RTC_OK
	end
	-- リセット実行時のコールバック
	-- @param comp RTC
	-- @param count 待機回数
	-- @return リターンコード
	function obj:onReset(comp, count)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTC状態取得時のコールバック
	-- @param state 状態
	-- @return 状態
	function obj:onGetComponentState(state)
		return state
	end
	-- 実行コンテキスト種別取得時のコールバック
	-- @param kind 種別
	-- @return 種別
	function obj:onGetKind(kind)
		return kind
	end
	-- プロファイル得時のコールバック
	-- @param profile プロファイル
	-- @return プロファイル
	function obj:onGetProfile(profile)
		return profile
	end
	-- RTC実行前に呼び出す処理
	-- onActivated、onAborting、onDeactivated、onResetが実行される
	function obj:invokeWorkerPreDo()
		self._worker:invokeWorkerPreDo()
    end
    -- RTC実行時に呼び出す処理
    -- onExecute、onErrorが実行される
	function obj:invokeWorkerDo()
		self._worker:invokeWorkerDo()
    end
    -- RTC実行後に呼び出す処理
    -- onStateUpdateが実行される
	function obj:invokeWorkerPostDo()
		self._worker:invokeWorkerPostDo()
    end
	-- 実行周期取得
	-- @return 実行周期(秒)
	function obj:getPeriod()
		return self._profile:getPeriod()
	end
	-- 実行周期取得
	-- @return 実行周期(Hz)
	function obj:getRate()
		local rate_ = self._profile:getRate()
		return self:onGetRate(rate_)
	end
	-- RTCのアクティブ化
	-- @param comp RTC
	-- @return リターンコード
	-- RTC_OK：onActivating、onActivatedがRTC_OKを返す
	-- BAD_PARAMETER：指定RTCがバインドされていない
	-- PRECONDITION_NOT_MET：非アクティブ状態以外の状態
	function obj:activateComponent(comp)
		self._rtcout:RTC_TRACE("activateComponent()")
		local ret_ = self:onActivating(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onActivating() failed.")
			return ret_
		end

		local rtobj_ = {object=nil}
		ret_ = self._worker:activateComponent(comp, rtobj_)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			return ret_
		end

		if not self._syncActivation then
			ret_ = self:onActivated(rtobj_.object, -1)
			if ret_ ~= self._ReturnCode_t.RTC_OK then

				self._rtcout:RTC_ERROR("onActivated() failed.")
			end
			--print(ret_)
			return ret_
		end


		self._rtcout:RTC_DEBUG("Synchronous activation mode. ")
        self._rtcout:RTC_DEBUG("Waiting for the RTC to be ACTIVE state. ")
		return self:waitForActivated(rtobj_.object)
	end
	-- RTCのアクティブ状態遷移まで待機する
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:waitForActivated(rtobj)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTCの非アクティブ化
	-- @param comp RTC
	-- @return リターンコード
	-- RTC_OK：onDeactivating、onDeactivated
	-- BAD_PARAMETER：指定RTCがバインドされていない
	-- PRECONDITION_NOT_MET：アクティブ状態以外の状態
	function obj:deactivateComponent(comp)
		self._rtcout:RTC_TRACE("deactivateComponent()")
		local ret_ = self:onDeactivating(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onDeactivating() failed.")
			return ret_
		end

		local rtobj_ = {object=nil}
		ret_ = self._worker:deactivateComponent(comp, rtobj_)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			return ret_
		end

		if not self._syncDeactivation then
			ret_ = self:onDeactivated(rtobj_[0], -1)
			if ret_ ~= self._ReturnCode_t.RTC_OK then
				self._rtcout:RTC_ERROR("onActivated() failed.")
			end
			return ret_
		end

		self._rtcout:RTC_DEBUG("Synchronous deactivation mode. ")
        self._rtcout:RTC_DEBUG("Waiting for the RTC to be INACTIVE state. ")
		return self:waitForDeactivated(rtobj_.object)

	end
	-- RTCの非アクティブ状態遷移まで待機する
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:waitForDeactivated(rtobj)
		return self._ReturnCode_t.RTC_OK
	end
	-- RTCのリセット
	-- @param comp RTC
	-- @return リターンコード
	-- RTC_OK：onResetting、onReset
	-- BAD_PARAMETER：指定RTCがバインドされていない
	-- PRECONDITION_NOT_MET：エラー状態以外の状態
	function obj:resetComponent(comp)
		self._rtcout:RTC_TRACE("resetComponent()")
		local ret_ = self:onResetting(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onResetting() failed.")
			return ret_
		end

		local rtobj_ = {object=nil}
		ret_ = self._worker:resetComponent(comp, rtobj_)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			return ret_
		end

		if not self._syncReset then
			ret_ = self:onReset(rtobj_[0], -1)
			if ret_ ~= self._ReturnCode_t.RTC_OK then
				self._rtcout:RTC_ERROR("onReset() failed.")
			end
			return ret_
		end

		self._rtcout:RTC_DEBUG("Synchronous deactivation mode. ")
        self._rtcout:RTC_DEBUG("Waiting for the RTC to be INACTIVE state. ")
		return self:waitForReset(rtobj_.object)

	end
	-- RTCのリセット完了まで待機する
	-- @param rtobj RTC
	-- @return リターンコード
	function obj:waitForReset(rtobj)
		return self._ReturnCode_t.RTC_OK
	end

	-- 実行状態を取得
	-- @return 実行状態
	function obj:isRunning()
		self._rtcout:RTC_TRACE("isRunning()")
		return self._worker:isRunning()
	end



	-- 実行状態を取得
	-- @return 実行状態
	function obj:is_running()
		self._rtcout:RTC_TRACE("is_running()")
		return self:isRunning()
	end

	-- 実行周期を取得
	-- @return 実行周期
	function obj:get_rate()
		return self:getRate()
	end
	-- 実行周期を設定
	-- @param rate 実行周期
	-- @return リターンコード
	function obj:set_rate(rate)
		return self:setRate(rate)
	end
	-- RTCのアクティブ化
	-- @param comp RTC
	-- @return リターンコード
	function obj:activate_component(comp)
		--print("activate_component")
		return self:activateComponent(comp)
	end
	-- RTCの非アクティブ化
	-- @param comp RTC
	-- @return リターンコード
	function obj:deactivate_component(comp)
		return self:deactivateComponent(comp)
	end
	-- RTCのリセット
	-- @param comp RTC
	-- @return リターンコード
	function obj:reset_component(comp)
		return self:resetComponent(comp)
	end
	-- RTCの状態取得
	-- @param comp RTC
	-- @return 状態
	function obj:get_component_state(comp)
		return self:getComponentState(comp)
	end
	-- 実行コンテキストの種別取得
	-- @return 種別
	function obj:get_kind()
		return self:getKind()
	end
	function obj:getKind()
		local kind_ = self._profile:getKind()
    	self._rtcout:RTC_TRACE("getKind() = %s", self:getKindString(kind_))
    	kind_ = self:onGetKind(kind_)
    	self._rtcout:RTC_DEBUG("onGetKind() returns %s", self:getKindString(kind_))
    	return kind_
	end
	-- RTCの追加
	-- @param comp RTC
	-- @return リターンコード
	function obj:addComponent(comp)
		self._rtcout:RTC_TRACE("addComponent()")
		local ret_ = self:onAddingComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: onAddingComponent(). RTC is not attached.")
			return ret_
		end
		
		ret_ = self._worker:addComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
		  	self._rtcout:RTC_ERROR("Error: ECWorker addComponent() faild.")
			return ret_
		end
		
		ret_ = self._profile:addComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: ECProfile addComponent() faild.")
			return ret_
		end
		
		ret_ = self:onAddedComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: onAddedComponent() faild.")
			self._rtcout:RTC_INFO("Removing attached RTC.")
			self._worker:removeComponent(comp)
			self._profile:removeComponent(comp)
			return ret_
		end
	
		self._rtcout:RTC_INFO("Component has been added to this EC.")
		return self._ReturnCode_t.RTC_OK
	end
	-- RTCの追加
	-- @param comp RTC
	-- @return リターンコード
	function obj:add_component(comp)
		return self:addComponent(comp)
	end
	-- RTCの削除
	-- @param comp RTC
	-- @return リターンコード
	function obj:removeComponent(comp)
		self._rtcout:RTC_TRACE("removeComponent()")
		local ret_ = self:onRemovingComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: onRemovingComponent(). RTC will not not attached.")
			return ret_
		end
	
		ret_ = self._worker:removeComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: ECWorker removeComponent() faild.")
			return ret_
		end
	
		ret_ = self._profile:removeComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: ECProfile removeComponent() faild.")
			return ret_
		end
	
		ret_ = self:onRemovedComponent(comp)
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Error: onRemovedComponent() faild.")
			self._rtcout:RTC_INFO("Removing attached RTC.")
			self._worker:removeComponent(comp)
			self._profile:removeComponent(comp)
			return ret_
		end
	
		self._rtcout:RTC_INFO("Component has been removeed to this EC.")
		return self._ReturnCode_t.RTC_OK
	end
	-- RTCの削除
	-- @param comp RTC
	-- @return リターンコード
	function obj:remove_component(comp)
		return self:removeComponent(comp)
	end
	-- プロファイル取得
	-- @return プロファイル
	function obj:get_profile()
		return self:getProfile()
	end
	-- プロファイル取得
	-- @return プロファイル
	function obj:getProfile()
		self._rtcout:RTC_TRACE("getProfile()")
		local prof_ = self._profile:getProfile()
		self._rtcout:RTC_DEBUG("kind: "..self:getKindString(prof_.kind))
		self._rtcout:RTC_DEBUG("rate: "..prof_.rate)
		self._rtcout:RTC_DEBUG("properties:")
		local props_ = Properties.new()
		NVUtil.copyToProperties(props_, prof_.properties)
		self._rtcout:RTC_DEBUG(props_)
		return self:onGetProfile(prof_)
	end
	-- 実行コンテキストの種別取得
	-- @return 種別
	function obj:getKindString(kind)
		return self._profile:getKindString(kind)
	end

	-- RTCの状態取得
	-- @param comp RTC
	-- @return 状態
	function obj:getComponentState(comp)
		local state_ = self._worker:getComponentState(comp)
		self._rtcout:RTC_TRACE("getComponentState() = "..self:getStateString(state_))
		if state_ == self._LifeCycleState.CREATED_STATE then
			self._rtcout:RTC_ERROR("CREATED state: not initialized "..
								 "RTC or unknwon RTC specified.")
		end

		return self:onGetComponentState(state_)
	end
	-- RTCの状態を文字列に変換
	-- @param state 状態
	-- @return 文字列化した状態
	function obj:getStateString(state)
		return self._worker:getStateString(state)
	end

	-- 実行コンテキストの停止
	-- @return リターンコード
	-- RTC_OK：onStopping、onStoppedがRTC_OKを返す
	-- PRECONDITION_NOT_MET：既に停止状態
	function obj:stop()
		self._rtcout:RTC_TRACE("stop()")
		local ret_ = self:onStopping()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onStopping() failed. Stopping EC aborted.")
			return ret_
		end

		ret_ = self._worker:stop()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("Invoking on_shutdown() for each RTC failed.")
			return ret_
		end

		ret_ = self:onStopped()
		if ret_ ~= self._ReturnCode_t.RTC_OK then
			self._rtcout:RTC_ERROR("onStopped() failed. Stopped EC aborted.")
			return ret_
		end

		return ret_
	end



	return obj
end


ExecutionContextBase.ExecutionContextFactory = {}
setmetatable(ExecutionContextBase.ExecutionContextFactory, {__index=GlobalFactory.Factory.new()})

function ExecutionContextBase.ExecutionContextFactory:instance()
	return self
end

return ExecutionContextBase
