---------------------------------------------------------------------------------------------------------
-- Distributed processing module in lua v1.0.4
-- Author: aimingoo@wandoujia.com
-- Copyright (c) 2015.12
--
-- The distributed processing module from NGX_4C architecture
--	1) N4C is programming framework.
--	2) N4C = a Controllable & Computable Communication Cluster architectur.
--
-- Usage:
--	register	: register_task()
--	executer	: execute_task(), run() 
--		*) limited executer		: run task at local only, distributed "taskId" is unsupported.
--			status - offline	: can read local and/or remote configuration, support local tasks.
--			status - online		: run as http client and send heartbeat to owner/supervision node or service(Etcd etc.)
--		*) unlimited executer	: accept remote task requrie, download(or load cached) and execute it.
--	dispatcher	: map()
--		*) task mapper			: it's limited task dispatcher, task proxy/redirect only, or daemon launcher.
--		*) task dispatcher 		: dispatch and run local and remote task, unlimited executer.
---------------------------------------------------------------------------------------------------------
local Promise = require('lib.Promise')

local mod_prefix = ({...})[1]
if mod_prefix then
	if mod_prefix == 'lib.Distributed' then -- hard load
		mod_prefix = ''
	else -- load by luarocks
		mod_prefix = mod_prefix .. '.'
	end
end
local def = require(mod_prefix .. 'infra.taskhelper')

local JSON = require('lib.JSON')
local JSON_decode = function(...) return JSON:decode(...) end
local JSON_encode = function(...) return JSON:encode_pretty(...) end

local reserved_tokens = {
	["?"]	= Promise.reject("unhandled placeholder '?'"),
	["::*"]	= Promise.reject("unhandled placeholder '::*'"),
	["::?"]	= Promise.reject("argument distributionScope scopePart invalid"),
	[":::"]	= Promise.reject("argument distributionScope/resourceId invalid"),
	[def.LOGGER] = Promise.resolve(false),
}

local invalid_task_center = {
	download_task = function(taskId) return Promise.reject('current node is not unlimited executer') end,
	register_task = function(taskDef) return Promise.reject('current node is not publisher') end
}

local invalid_resource_center = {
	require = function(resId) return Promise.reject('current node is not dispatcher') end
}

local invalid_promised_request = function(arrResult)
	return Promise.reject('promised request is unsupported at current node')
end

-- mix/copy fields from ref to self
local function mix(self, ref, expanded)
	if ref == nil then return self end

	if type(ref) == 'function' then return expanded and ref or nil end
	if type(ref) ~= 'table' then return ref end

	self = (type(self) == 'table') and self or {}
	for key, value in pairs(ref) do
		self[key] = mix(self[key], value, expanded)
	end
	return self
end

-- ex:
--	local obj = {}, f = function(self, a, b) self.A=a; self.B=b end
--	local ff = bind(f, obj)
--	ff(1,2) // non-self
local function bind(...)
	local function with_arguments(t, ...) return t[1](t[2], ...) end
	local function ignore_arguments(t) return t[1](select(2, unpack(t))) end
	return setmetatable({...}, {
		__call = (#{...} > 2) and ignore_arguments or with_arguments
	})
end

---------------------------------------------------------------------------------------------------------
--	standard logger and rejected inject
---------------------------------------------------------------------------------------------------------
local ignore_rejected = Promise.resolve;

-- internal logger for default rejected only
-- 		- <this> is prebind array of [worker, message]
function internal_logger(self, task)
	return task and self[1]:run(task, self[2])
end

-- return resolved promise, and mute rejected message always
--		- standard implementations only 2 lines:
function internal_default_rejected(worker, message)
	local newWorker = setmetatable({default_rejected = ignore_rejected}, {__index = worker})
	return worker:require(worker.LOGGER):andThen(bind(internal_logger, {newWorker, message}));
end

-- standard local logger, expand by Harpseal only
reserved_tokens[def.LOGGER] = function(_, message)
	local msg = type(message) == 'table' and message or { reason = message, action = 'unknow' }
	local e, e_message = msg.reason
	local header = os.date('%Y-%m-%d %H:%M:%S [error] ')
		.. (msg.action or '')
		.. (msg.to     and (' the '..msg.to) or '')
		.. (msg.scope  and (' in '..msg.scope) or '')
		.. (msg.task   and (' at '..msg.task) or '');
	if e then
		e_message = e.message and e.stack and (e.message .. ', ' .. e.stack) or e.stack or e.message
	end
	print(header .. ', ' .. (e_message or (type(e)=='string' and e or JSON_encode(e)) or 'no reason.'))
end

-- enter a sub-processes with privated rejected method
function enter(f, rejected)
	return function(...)
		local ok, result = pcall(f, ...)
		return ok and Promise.resolve(result):catch(rejected)
			or rejected({ message = result, stack = debug.traceback() })
	end
end

-- return rejected message as error reason
function reject_me(self)
	return function()
		return Promise.reject(tostring(self))
	end
end

---------------------------------------------------------------------------------------------------------
--	meta promisedTask core utils
---------------------------------------------------------------------------------------------------------

local function isTaskId(str)
	return (string.len(str)==5+32) and string.match(str, '^task:')
end

local function isDistributedTask(obj)
	return ((type(obj.map) == 'string') and isTaskId(obj.map) and (obj.scope ~= nil))
		or ((type(obj.run) == 'string') and isTaskId(obj.run))
		or ((type(obj.run) == 'table'))
		or ((type(obj.run) == 'function'))
end

local function isDistributedTasks(arr)
	for _, value in ipairs(arr) do
		if isDistributedTask(value) then
			return true
		end
	end
	return false
end

local function promise_arguments(t) return t.arguments end
local function promise_distributed_task(worker, task)
	-- task as taskDef, rewrite task.arguments
	local args = task.arguments and isDistributedTask(task.arguments) and worker:run(task):andThen(promise_arguments) or task.arguments;
	if task.run ~= nil then
		return worker:run(task.run, args)
	elseif task.map ~= nil then
		return worker:map(task.scope, task.map, args)
	else
		return Promise.reject("none distribution method in taskDef");
	end
end

local function promise_distributed_tasks(worker, arr)
	local tasks = {}
	for _, value in ipairs(arr) do
		table.insert(tasks, isDistributedTask(value) and promise_distributed_task(worker, value) or value)
	end
	-- assert(next(tasks), 'try distribution empty tasks')
	return Promise.all(tasks)
end

-- rewrite members, promised already
local function promise_member_rewrite(promises)
	local taskOrder = table.remove(promises) -- pop taskOrder
	local p = taskOrder.promised
	local keys = assert(p and p.keys, 'cant find promised.keys in metatable')
	for i, key in ipairs(keys) do
		taskOrder[key] = promises[i]
	end
	return Promise.resolve(taskOrder)
end

-- promise all members
local function promise_static_member(worker, picker, order)
	local fakeOrder = function(obj) return setmetatable({}, {__index=obj}) end
	if order.promised then
		local promises, promised, keys = {}, order.promised, order.promised.keys
		if keys then
			for i, key in pairs(keys) do
				local value = promised[i]
				if isDistributedTask(value) then
					table.insert(promises, promise_distributed_task(worker, value))
				elseif #value > 0 then
					table.insert(promises, promise_distributed_tasks(worker, value))
				else
					-- assert(promise_static_member(value), 'invalid value promised')
					table.insert(promises, promise_static_member(worker, picker, fakeOrder(value)))
				end
			end
			table.insert(promises, order) -- push order
			return Promise.all(promises):andThen(promise_member_rewrite):andThen(picker)
		else
			-- assert(promised.promised, 'no promised method and promises')
			return Promise.resolve(order):andThen(picker)
		end
	end
end

local function pickTaskResult(worker, taskOrder)
	local p = taskOrder.promised
	if p and p.promised then -- process by taskDef.promised
		local ok, taskResult = pcall(p.promised, worker, taskOrder)
		if not ok then
			local e = { message = taskResult, stack = debug.traceback() }
			local reason = { reason = e, action = 'taskDef:promised', task = taskOrder.taskId }
			local task = taskOrder.taskId or "local task"
			return worker:default_rejected(reason)
				:andThen(reject_me("taskDef promised exception '" + e.message + "' at " + task));
		end
		return taskResult or taskOrder
	end
	return taskOrder 
end

local function kickTaskResult(self, reason)
	local worker, taskOrder = unpack(self)
	local p = taskOrder.promised
	if p and p.rejected then -- mute by taskDef.rejected
		local ok, taskResult = pcall(p.rejected, worker, reason)
		if not ok then
			local e = { message = taskResult, stack = debug.traceback() }
			local reason = { reason = reason, action = 'taskDef' }
			local reason2 = { reason = e, action = 'taskDef:rejected', task = taskOrder.taskId }
			local task = taskOrder.taskId or "local task"
			return Promise.all({worker:default_rejected(reason), worker:default_rejected(reason2)})
				:andThen(reject_me("taskDef rejected exception '" + e.message + "' at " + task));
		end
		return taskResult or taskOrder
	end
	return Promise.reject(reason) 
end

local function extractTaskResult(taskOrder)
	if type(taskOrder) == 'table' then
		if #taskOrder > 0 then
			for _, item in ipairs(taskOrder) do
				if type(item)=='table' then extractTaskResult(item) end
			end
		else
			local meta = getmetatable(taskOrder)
			if meta then
				local taskDef = assert(meta.__index, 'invalid taskOrder') -- @see makeTaskOrder() and makeTaskMetaTable()
				local p, ignored = taskDef.promised, {promised=true, distributed=true, rejected=true, taskId=true}
				if p and p.keys then -- rewrited
					for _, result in pairs(taskOrder) do extractTaskResult(result) end
				end
				for key, result in pairs(taskDef) do
					if not ignored[key] and (type(result) ~= 'function') and (rawget(taskOrder, key) == nil) then
						taskOrder[key] = result
					end
				end
			end
		end
	end
	return taskOrder
end

local function extractMapedTaskResult(results)
	-- the <result> resolved with {body: body, headers: response.headers}
	--	*) @see request.get() in distributed_request()
	local maped = {}
	for i, result in ipairs(results) do
		local ok, result = pcall(JSON_decode, result.body)
		if not ok then
			return  Promise.reject({index=i, reason="JSON decode error of: " .. result})
		end
		maped[i] = result
	end
	return maped
end

-- scan static members and preprocess
local function preProcessMembers(obj)
	local keys, promised = {}, {}
	-- distribution methods
	for key, value in pairs(obj) do
		if type(value) == 'table' then
			if isDistributedTask(value) or isDistributedTasks(value) then
				table.insert(keys, key)
				table.insert(promised, value)
				obj[key] = nil
			else
				local p = preProcessMembers(value)
				if p then
					table.insert(keys, key)
					table.insert(promised, p)
					obj[key] = nil
				end
			end
		end
	end
	-- process methods
	promised.keys = (#keys > 0) and keys or nil
	promised.promised = obj.promised or nil
	promised.rejected = obj.rejected or nil
	-- cache to obj.promised
	if next(promised) ~= nil then
		obj.promised = promised
		return obj
	end
end

---------------------------------------------------------------------------------------------------------
-- MetaPromisedTask
---------------------------------------------------------------------------------------------------------

-- meta promisedTask
local MetaPromisedTask = {
	__call = function(t, resolve, reject)
		local worker, order = unpack(t)
		local picker, kicker = bind(pickTaskResult, worker), bind(kickTaskResult, t)
		return Promise.resolve(promise_static_member(worker, picker, order) or order):catch(kicker)
			:andThen(resolve, reject)
	end
}

-- get a promisedTask
local function makeTaskMetaTable(taskDef)
	return { __index = taskDef }
end

-- make original taskOrder
local function makeTaskOrder(meta)
	return setmetatable({}, meta)
end

local function asPromisedTask(...)
	return setmetatable({ ... }, { __call=MetaPromisedTask.__call })
end

---------------------------------------------------------------------------------------------------------
-- internal methods
---------------------------------------------------------------------------------------------------------
local GLOBAL_CACHED_TASKS = {}
GLOBAL_CACHED_TASKS[def.TASK_SELF] = {
	promised = function() return Promise.reject('dont direct execute def.TASK_SELF') end
};
GLOBAL_CACHED_TASKS[def.TASK_RESOURCE] = {
	promised = function(self, resId) return self:require(resId) end
};

-- need prebind context to self
local function distributed_task(self, taskDef)
	local worker, taskId = unpack(self);

	function replace_task_self(obj)
		if type(obj) == 'table' then
			for key, value in pairs(obj) do
				if type(value) == 'table' then
					if isDistributedTask(value) and (value.map == worker.TASK_SELF) then
						value.map = taskId
					elseif #value > 0 then
						for _, value2 in ipairs(value) do replace_task_self(value2) end
					else
						replace_task_self(value)
					end
				end
			end
		end
	end

	local ok, taskObject = pcall(def.decode, taskDef)
	if not ok then
		local e = { message = taskResult, stack = debug.traceback() }
		return worker:default_rejected({action = 'taskDef:decode', reason = e, task = taskId})
			:andThen(reject_me("decode exception '" .. e.message .. "'for downloaded " .. taskId));
	end

	-- define taskDef.taskId, and will hide it in extractTaskResult()
	taskObject.taskId = taskId

	-- replace TASK_SELF in task.map only, with task.run.arguments.map
	replace_task_self(taskObject)

	-- call taskDef.distributed
	if taskObject.distributed then
		ok = pcall(taskObject.distributed, worker, taskObject)
		if not ok then
			local e = { message = taskResult, stack = debug.traceback() }
			return worker:default_rejected({action = 'taskDef:distributed', reason = e, task = taskId})
				:andThen(reject_me("distributed method exception '" .. e.message .. "'in " .. taskId));
		end
	end

	-- preprocess members
	preProcessMembers(taskObject)
	return taskObject
end

local function inject_default_handles(opt)
	if not opt.task_register_center then
		opt.task_register_center = invalid_task_center
	else
		local center = opt.task_register_center;
		if not center.download_task then center.download_task = invalid_task_center.download_task end
		if not center.register_task then center.register_task = invalid_task_center.register_task end
	end

	if not opt.resource_status_center then
		opt.resource_status_center = invalid_resource_center
	else
		local center = opt.resource_status_center;
		if not center.require then center.require = invalid_resource_center.require end
	end

	return opt
end

local function internal_parse_scope(self, center, distributionScope)
	-- "?" or "*" is filted by self.require()
	if string.len(distributionScope) < 4 then return self:require(":::") end

	-- systemPart:pathPart:scopePart
	--	*) rx_tokens = /^([^:]+):(.*):([^:]+)$/
	local parts, scopePart = string.match(distributionScope, '^(.*):([^:]+)$')
	if not parts then return self:require(":::") end

	-- TODO: dynamic scopePart parser, the <parts> is systemPart:pathPart
	return ((scopePart == '?') and self:require("::?")
		or ((scopePart == '*') and Promise.resolve(center.require(parts))
		or Promise.reject("dynamic scopePart is not support for '"..distributionScope.."'")));
end

local function internal_download_task(self, center, taskId)
	local WORKER_CACHED_TASKS = GLOBAL_CACHED_TASKS[self] or {}
	local function cached_as_promise(taskDef)
		if not taskDef then
			return Promise.reject('unknow '.. taskId ..' in D.execute_task()')
		end

		local resolved_taskMeta = Promise.resolve(makeTaskMetaTable(taskDef))
		WORKER_CACHED_TASKS[taskId] = resolved_taskMeta
		return resolved_taskMeta
	end

	return WORKER_CACHED_TASKS[taskId] or Promise.resolve(center.download_task(taskId))
		:andThen(bind(distributed_task, {self, taskId}))
		:andThen(cached_as_promise);
end

-- need prebind context to self
local function internal_execute_task(self, taskMeta)
	-- local worker, args = unpack(self)
	local taskOrder = mix(makeTaskOrder(taskMeta), self[2]);
	return Promise.new(asPromisedTask(self[1], taskOrder))
end

-- -------------------------------------------------------------------------------------------------------
-- Distributed processing methods
-- 	*) return promise object by these methods
-- 	*) MUST: catch error by caller for these interfaces
-- -------------------------------------------------------------------------------------------------------
local D = setmetatable({}, {__index=def})

function D:run(task, args)
	local t = type(task)

	function rejected_arguments(reason)
		local reason2 = {reason = reason, action = 'run:arguments', task = (t == 'string' and task or nil)}
		return self:default_rejected(reason2)
			:andThen(reject_me("arguments promise rejected"))
	end
	function rejected_extract(reason)
		return self:default_rejected({reason = reason, action = 'run'})
			:andThen(reject_me("extract task results fail when run local taskObject"))
	end
	function rejected_call(reason)
		local message = "direct call exception '" .. (reason and reason.message or JSON_encode(reason)) .. "'"
		return self:default_rejected({reason = reason, action = 'run:direct'})
			:andThen(reject_me(message))
	end

	-- direct call, or call from promise_distributed_task()
	local promised_args = Promise.resolve(args):catch(rejected_arguments)

	if t == 'function' then
		-- direct call, or call from promise_distributed_task()
		return promised_args:andThen(enter(bind(task, self), rejected_call))
	elseif (t == 'string') and isTaskId(task) then
		-- execute registed taskDef with taskId
		return promised_args:andThen(function(args)
			return self:execute_task(task, args)
		end)
	elseif t == 'table' then
		-- run local taskObject, will skip decode and ignore taskDef.distributed()
		local taskDef = preProcessMembers(task) or task
		local taskMeta = makeTaskMetaTable(taskDef)
		local taskOrder = mix(makeTaskOrder(taskMeta), args)
		return Promise.new(asPromisedTask(self, taskOrder))
			:andThen(enter(extractTaskResult, rejected_extract))
	else
		return Promise.reject('unknow task type "' .. t .. '" in Distributed.run()')
	end
end

function D:map(distributionScope, taskId, args)
	function rejected_responses(reason)
		return self:default_rejected({action = 'map:request', reason = reason, scope = distributionScope, to = taskId})
			:andThen(reject_me("invalid response from distributed requests"))
	end
	function rejected_scope(reason)
		return self:default_rejected({reason = reason, action = 'map:scope', scope = distributionScope, to = taskId})
			:andThen(reject_me("invalid distribution scope '".. distributionScope .."'"))
	end
	function rejected_arguments(reason)
		return self:default_rejected({reason = reason, action = 'map:arguments', scope = distributionScope, to = taskId})
			:andThen(reject_me("arguments promise rejected"))
	end
	function rejected_extract(reason)
		return self:default_rejected({reason = reason, action = 'map', scope = distributionScope, to = taskId})
			:andThen(reject_me("extract maped task results fail"))
	end

	local scope = self:require(distributionScope):catch(rejected_scope)
	local args2 = Promise.resolve(args):catch(rejected_arguments)
	return Promise.all({scope, taskId, args2})  -- ignore worker?
		:andThen(enter(self.distributed_request, rejected_responses))
		:andThen(enter(extractMapedTaskResult, rejected_extract))
end

return {
	new = function(_, opt)
		local instance = setmetatable({},  { __index = D });
		local options = { system_route = setmetatable({}, { __index = reserved_tokens }) };

		local function system_route(token)
			return options.system_route[token]
		end

		function instance:upgrade(newOptions)
			inject_default_handles(mix(options, newOptions, true))
			table.foreachi({'distributed_request', 'default_rejected'}, function(_, key)
				if newOptions[key] then self[key] = newOptions[key] end
			end)
		end

		function instance:require(token)
			return Promise.resolve(system_route(token) or
				internal_parse_scope(self, options.resource_status_center, token))
		end

		function instance:execute_task(taskId, args)
			function rejected_extract(reason)
				return self:default_rejected({reason = reason, action = 'execute', task = taskId})
					:andThen(reject_me.bind("extract task results fail when execute " .. taskId));
			end
			return internal_download_task(self, options.task_register_center, tostring(taskId))
				:andThen(bind(internal_execute_task, {self, args}))
				:andThen(enter(extractTaskResult, rejected_extract))
		end

		function instance:register_task(task)
			return Promise.resolve(options.task_register_center.register_task(
				(type(task) == 'string') and task or def.encode(task)))
		end

		-- set defaults and return instance
		GLOBAL_CACHED_TASKS[instance] = {}
		instance.distributed_request = invalid_promised_request
		instance.default_rejected = internal_default_rejected
		instance:upgrade(opt)
		return instance;
	end,

	infra = mod_prefix and {
		taskhelper = def,
		httphelper = require(mod_prefix..'infra.httphelper'),
	} or nil,

	tools = mod_prefix and {
		taskloader = require(mod_prefix..'tools.taskloader'),
		loadkit = require(mod_prefix..'tools.loadkit'),
	} or nil,
}