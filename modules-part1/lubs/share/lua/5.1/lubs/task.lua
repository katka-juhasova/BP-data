local tasks = {}

local function exists (name)
	if tasks[name] == nil then
		return false
	else
		return true
	end
end

local function exec (name)
	if tasks[name] == nil then
		error("no task named '" .. name .. "' has been registered")
	else
		for i, depName in ipairs(tasks[name].deps) do
			exec(depName)
		end
		tasks[name].func()
	end
end

local function get (name)
	if tasks[name] == nil then
		return nil
	else
		return tasks[name]
	end
end

local function task (name, depsOrFunc, func)

	if type(name) ~= 'string' then
		error('string expected for argument 1')
	end

	if tasks[name] ~= nil then
		error("task '" .. name .. "' has already been registered")
	end

	local t = { deps = {} }

	if type(depsOrFunc) == 'table' then
		t.deps = depsOrFunc
		if type(func) == 'function' then
			t.func = func
		else
			error('function expected for argument 3')
		end
	elseif type(depsOrFunc) == 'function' then
		t.func = depsOrFunc
	else
		error('table or function expected for argument 2')
	end

	tasks[name] = t
end

return {
	exists = exists,
	exec = exec,
	get = get,
	task = task
}
