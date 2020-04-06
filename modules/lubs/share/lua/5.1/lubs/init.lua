local path = require('path')
local uv = require('luv')
local task = require('lubs.task')
local watch = require('lubs.watch')
local timers = require('lubs.utils').timers

local running = false

return {
	init = function (args)

		if running == true then return end

		running = true

		local sigint = uv.new_signal()

		-- watch for CTRL-C
		uv.signal_start(sigint, "sigint", function(signal)
			print("Shutting down")
			os.exit(1)
		end)

		-- execute all the task's that we're passed in as arguments
		for i, name in ipairs(args) do

			local t = task.get(name)

			-- exec its dependencies first, then exec the task
			if t ~= nil then
				task.exec(name)
			else
				error('no task named ' .. name .. ' has been registered')
			end
		end

		if watch.count() > 0 then
			local i = timers.set_interval(watch.interval, function(timer)
				watch.tick()
			end)
			uv.run()
		end
	end,
	task = require('lubs.task').task,
	src = require('lubs.src').src,
	dest = require('lubs.dest').dest,
	watch = require('lubs.watch').watch
}
