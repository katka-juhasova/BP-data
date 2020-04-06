---------------------------------------------------------------------------------------------------------
-- Distributed task loader
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.11
--
-- Note:
--	*) load taskObject from task script file with the util class.
--	*) task helper class inherite and enhanced.
--	*) need call register_task().
---------------------------------------------------------------------------------------------------------
local prefix = string.gsub(({...})[1] or '', 'tools.taskloader$', '')
local def = require(prefix..'infra.taskhelper')
local loadkit = require('tools.loadkit')
local Loader = setmetatable({}, {__index=def})

local isTaskId = function(str)
	return (string.len(str)==5+32) and string.match(str, '^task:')
end

local toFileName = loadkit.make_loader('lua', function(file, module_name, file_path)
	return file_path
end)

function Loader:loadObject(taskObject)
	local taskDef = def.encode(taskObject)
	return self.publisher:register_task(taskDef)
end

function Loader:loadScript(taskScript)
	local fakedDistributedMod = setmetatable({}, {
		__index = function(t, key)
			return self[key] or error('invaled distributed method');
		end
	})

	local task_def_loader_env = setmetatable({
		["def"] = fakedDistributedMod
	}, {__index = _G})

	local init = loadstring(taskScript)
	setfenv(init, task_def_loader_env)

	local ok, result = pcall(init)
	if not ok then
		print('ERROR in script parse or pre-execute, ', result .. ',' .. debug.traceback())
	end

	return self:loadObject(result)
end

function Loader:loadByFile(fileName)
	local result, errReason = loadfile(fileName)
	if not result then
		print('ERROR when loadfile ' .. errReason .. ',' .. debug.traceback())
		error(errReason)
	else
		return self:loadScript(string.dump(result))
	end
end

function Loader:loadByModule(modName)
	return self:loadByFile(toFileName(modName))
end

local function enhance(Loader, task)
	if (type(task) == 'string') and not isTaskId(task) then
		return Loader:loadByModule(task)
	else
		return task
	end
end

local taskloader = setmetatable({
	-- create
	new = function(self, conf)
		return setmetatable({
			publisher = conf.publisher
		}, {__index=self})
	end,

	-- support modName for task
	map = function(self, scope, task, ...) return def.map(self, scope, enhance(self, task), ...) end,

	-- support modName for task
	reduce = function(self, scope, task, ...) return  def.reduce(self, scope, enhance(self, task), ...) end,

	-- support modName for task and deamon
	daemon = function(self, scope, task, daemon, ...) return  def.daemon(self, scope, enhance(self, task), enhance(self, daemon), ...) end,
}, {__index=Loader})

return taskloader