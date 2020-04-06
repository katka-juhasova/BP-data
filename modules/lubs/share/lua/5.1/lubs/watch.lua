local path = require('path')
local task = require('lubs.task')
local watches = {}
local defaultOptions = { param = 'fm', recurse = true }

local changeMap = {}

return {
	interval = 1000,
	count = function ()
		local total = 0
		for _ in pairs(watches) do
			total = total + 1
		end
		return total
	end,
	tick = function ()

		local tasksToExec = {}

		-- build up a list of tasks to run
		for blob, w in pairs(watches) do

			path.each(blob, function (p, mode)

				if mode ~= 'directory' then

					if changeMap[p] ~= nil then

						local mtime = path.mtime(p)

						if changeMap[p] ~= mtime then
							changeMap[p] = mtime
							table.insert(tasksToExec, w.tasks)
						end

					else
						changeMap[p] = path.mtime(p)
					end

				end

			end, w.options)

		end

		-- run all the tasks
		for i, taskList in ipairs(tasksToExec) do
			for ii, taskName in ipairs(taskList) do
				task.exec(taskName)
			end
		end
	end,
	watch = function (blob, optionsOrTasks, tasks)

		if type(blob) ~= 'string' then
			error('string expected for argument 1')
		end

		if type(optionsOrTasks) ~= 'table' then
			error('table or function expected for argument 2')
		end

		local w = { options = defaultOptions }

		if type(tasks) == 'table' then
			w.options = optionsOrTasks
			w.tasks = tasks
		else
			w.tasks = optionsOrTasks
		end

		watches[blob] = w
	end
}
