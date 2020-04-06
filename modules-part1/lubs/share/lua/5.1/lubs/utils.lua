local uv = require('luv')

local function set_interval(interval, callback)
	local timer = uv.new_timer()
	local function ontimeout()
		callback(timer)
	end
	uv.timer_start(timer, interval, interval, ontimeout)
	return timer
end

local function clear_interval(timer)
	uv.timer_stop(timer)
	uv.close(timer)
end

return {
	timers = {
		set_interval = set_interval,
		clear_interval = clear_interval
	}
}
