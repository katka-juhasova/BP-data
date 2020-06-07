---------------------------------
--! @file TimeValue.lua
--! @brief 時間ヘルパ関数定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local TimeValue= {}
--_G["openrtm.TimeValue"] = TimeValue

local TIMEVALUE_ONE_SECOND_IN_USECS = 1000000

-- 時間ヘルパ関数オブジェクト初期化
-- @return 関数オブジェクト
TimeValue.new = function(sec, usec)
	local obj = {}
	-- 時間を引く際のオペレータ
	-- @param self 自身のオブジェクト
	-- @param tm 引く時間関数オブジェクト
	-- @return 引き算後の時間
	local sub_func = function(self, tm)
		local res = TimeValue.new()
		--print("test",self.tv_sec, self.tv_usec, tm.tv_sec, tm.tv_usec)
		if self.tv_sec >= tm.tv_sec then
			if self.tv_usec >= tm.tv_usec then
				res.tv_sec  = self.tv_sec  - tm.tv_sec
				res.tv_usec = self.tv_usec - tm.tv_usec
			else
				res.tv_sec  = self.tv_sec  - tm.tv_sec - 1
				res.tv_usec = (self.tv_usec + TIMEVALUE_ONE_SECOND_IN_USECS) - tm.tv_usec
			end
		else
			if tm.tv_usec >= self.tv_usec then
				res.tv_sec  = -(tm.tv_sec  - self.tv_sec)
				res.tv_usec = -(tm.tv_usec - self.tv_usec)
			else
				res.tv_sec  = -(tm.tv_sec - self.tv_sec - 1)
				res.tv_usec = -(tm.tv_usec + TIMEVALUE_ONE_SECOND_IN_USECS) + self.tv_usec
			end
		end

		res:normalize()
		return res
	end
	-- 時間を足す際のオペレータ
	-- @param self 自身のオブジェクト
	-- @param tm 足す時間関数オブジェクト
	-- @return 足し算後の時間
	local add_func = function(self, tm)
		local res = TimeValue.new()
		res.tv_sec  = self.tv_sec  + tm.tv_sec
		res.tv_usec = self.tv_usec + tm.tv_usec
		if res.tv_usec > TIMEVALUE_ONE_SECOND_IN_USECS then
			res.tv_sec = res.tv_sec + 1
			res.tv_usec = res.tv_usec - TIMEVALUE_ONE_SECOND_IN_USECS
		end
		res:normalize()
		return res
	end
	-- 時間を文字列に変換するオペレータ
	-- @param self 自身のオブジェクト
	-- @return 文字列
	local str_func = function(self)
		local ret = ""..self.tv_sec..(self.tv_usec / TIMEVALUE_ONE_SECOND_IN_USECS)
		return ret
	end


	setmetatable(obj, {__add =add_func,__sub=sub_func,__tostring=str_func})
	-- 秒数取得
	-- @return 秒数
	function obj:sec()
		return self.tv_sec
	end
	-- マイクロ秒数取得
	-- @return マイクロ秒数
	function obj:usec()
		return self.tv_usec
	end
	-- 時間設定
	-- @param _time 時間
	-- @return 自身のオブジェクト
	function obj:set_time(_time)
		self.tv_sec  = _time - _time%1
		self.tv_usec = (_time - self.tv_sec) * TIMEVALUE_ONE_SECOND_IN_USECS
		self.tv_usec = self.tv_usec - self.tv_usec%1
		return self
	end
	-- 時間を数値に変換
	-- @return 数値
	function obj:toDouble()
		return self.tv_sec + self.tv_usec / TIMEVALUE_ONE_SECOND_IN_USECS
	end
	-- 時間の正負を判定
	-- @return 1：正、-1：負、0：0
	function obj:sign()
		if self.tv_sec > 0 then
			return 1
		end
		if self.tv_sec < 0 then
			return -1
		end
		if self.tv_usec > 0 then
			return 1
		end
		if self.tv_usec < 0 then
			return -1
		end
		return 0
	end

	-- 時間の正規化
	-- マイクロ秒数が1000000を超えていた場合に秒に変換
	function obj:normalize()
		if self.tv_usec >= TIMEVALUE_ONE_SECOND_IN_USECS then
			self.tv_sec = self.tv_sec + 1
			self.tv_usec = self.tv_usec - TIMEVALUE_ONE_SECOND_IN_USECS

			while self.tv_usec >= TIMEVALUE_ONE_SECOND_IN_USECS do
				self.tv_sec = self.tv_sec + 1
				self.tv_usec = self.tv_usec - TIMEVALUE_ONE_SECOND_IN_USECS
			end

		elseif self.tv_usec <= -TIMEVALUE_ONE_SECOND_IN_USECS then
			self.tv_sec = self.tv_sec - 1
			self.tv_usec = self.tv_usec + TIMEVALUE_ONE_SECOND_IN_USECS

			while self.tv_usec <= -TIMEVALUE_ONE_SECOND_IN_USECS do
				self.tv_sec = self.tv_sec - 1
				self.tv_usec = self.tv_usec + TIMEVALUE_ONE_SECOND_IN_USECS
			end
		end


		if self.tv_sec >= 1 and self.tv_usec < 0 then
			self.tv_sec = self.tv_sec - 1
			self.tv_usec = self.tv_usec + TIMEVALUE_ONE_SECOND_IN_USECS

		elseif self.tv_sec < 0 and self.tv_usec > 0 then
			self.tv_sec = self.tv_sec + 1
			self.tv_usec = self.tv_usec - TIMEVALUE_ONE_SECOND_IN_USECS
		end
	end

	if type(sec) == "string" then
		sec = tonumber(sec)
	end
	if type(usec) == "string" then
		usec = tonumber(usec)
	end
	if sec ~= nil and usec == nil then
		local dbHalfAdj_ = 0.0
		if sec >= 0.0 then
			dbHalfAdj_ = 0.5
		else
			dbHalfAdj_ = -0.5
		end

		obj.tv_sec = sec - sec%1
		obj.tv_usec = (sec - obj.tv_sec) *
                          TIMEVALUE_ONE_SECOND_IN_USECS + dbHalfAdj_
		obj.tv_usec = obj.tv_usec - obj.tv_usec%1
		obj:normalize()

		return obj
	end
	if sec == nil then
      obj.tv_sec = 0
    else
      obj.tv_sec = sec - sec%1
	end

    if usec == nil then
      obj.tv_usec = 0
    else
      obj.tv_usec = usec - usec%1
	end
    obj:normalize()
	return obj

end


return TimeValue
