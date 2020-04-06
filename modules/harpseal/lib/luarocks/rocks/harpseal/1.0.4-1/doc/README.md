# harpseal

harpseal is implement of PEDT - Parallel Exchangeable Distribution Task specifications for lua.

PEDT v1.1 specifications supported.

#### Table of Contents

* [install](#install)
* [import and usage](#import-and-usage)
* [options](#options)
* [interfaces](#interfaces)
  * [pedt:run](#pedtrun)
  * [pedt:map](#pedtmap)
  * [pedt:execute_task](#pedtexecute_task)
  * [pedt:register_task](#pedtregister_task)
  * [pedt:require](#pedtrequire)
  * [pedt:upgrade](#pedtupgrade)
  * [pedt.LOGGER](#pedtlogger)
  * [pedt.TASK_XXX](#pedttask_xxx)
  * [pedt.version](#pedtversion)
* [helpers](#helpers)
  * [Harpseal.infra.taskhelper](#harpsealinfrataskhelper)
  * [Harpseal.infra.httphelper](#harpsealinfrahttphelper)
  * [Harpseal.tools.taskloader](#harpsealtoolstaskloader)
  * [pedt.lua utility](#pedtlua-utility)
    * [action: help](#action-help)
    * [action: add](#action-add)
    * [action: run](#action-run)
    * [action: methods ](#action-methods)
* [testcase](#testcase)
* [history](#history)

# install

> git clone https://github.com/aimingoo/harpseal

or

> luarocks install harpseal

# import and usage

``` lua
-- require when installed by luarocks
local Harpseal = require('harpseal');

-- or hard load from lua_path/directory
-- local Harpseal = require('lib.Distributed');

local options = {};
local pedt = Harpseal:new(options);

pedt:run(..)
	:andThen(function(result){
		..
	})
```

# options

the full options schema:

``` lua
options = {
    distributed_request = function(arrResult) .. end, -- a http client implement
    default_rejected: function(message) { .. }, -- a default rejected inject
    system_route = { .. }, -- any key/value pairs
	task_register_center = {
		download_task = function(taskId) .. end, -- PEDT interface
		register_task = function(taskDef) .. end,  -- PEDT interface
	},
	resource_status_center = {
		require = function(resId) .. end,-- PEDT interface
	}
}
```

# interfaces

> for detail, @see ${harpseal}/infra/specifications/*
> 
> for Promise in lua, @see [https://github.com/aimingoo/Promise](https://github.com/aimingoo/Promise)

all interfaces are promise supported except pedt:upgrade() and helpers.

## pedt:run

``` lua
function pedt:run(task, args)
```

run a task (taskId, function or taskObject) with args.

## pedt:map

``` lua
function pedt:map(distributionScope, taskId, args)
```

map taskId to distributionScope with args, and get result array.

distributionScope will parse by pedt:require().

## pedt:execute_task

``` lua
function pedt:execute_task(taskId, args)
```

run a taskId with args. pedt:run(taskId) will call this.

## pedt:register_task

``` lua
function pedt:register_task(task)
```

run a task and return taskId.

the "task" is a taskDef text or local taskObject.

## pedt:require

``` lua
function pedt:require(tokevan)
```

require a resource by token. the token is distributionScope or system token, or other.

this is n4c expanded interface, resource query interface emmbedded.

## pedt:upgrade

``` lua
function pedt:upgrade(newOptions)
```

upgrade current Harpseal/PEDT instance with newOptions. @see [options](#options)

this is harpseal expanded interface.

## pedt.LOGGER

this is expanded reserved tokens. it's constant:

> LOGGER: "!"

so, you can option/reset/upgrade local default logger in your code:

``` javascript
pedt:upgrade({ system_route = {[pedt.LOGGER]: function(_, message) {
  console.log(message)
}} });
```

or disable it:

``` javascript
pedt:upgrade({ system_route = {[pedt.LOGGER] = Promise.resolve(false)} }),
```

or resend message to remote nodes/scope:

``` javascript
// @see ${redpoll}/testcase/t_executor.js
pedt:register_task(a_task_def):andThen(set_remote_logger)
```

and, you can call the logger at anywhere:

``` lua
pedt:require(pedt.LOGGER):andThen(function(logger)
  pedt:run(logger, message)
end)
```

or public a log_print_task, register and run it:

``` lua
local log_print_task = {
  message = 'will replaced',
  task = def:require(def.LOGGER),
  promised = function(self, log)
    return self:run(log.task, log.message))
  end
}
local taskId = '<get result from pedt.register_task(log_print_task)>'
pedt:run(taskId, {message = 'some notice/error information'})
```

this is harpseal expanded interface.

## pedt.TASK_XXX

some task constants, inherited from def.TASK_XXX in Harpseal.infra.taskhelper. include:

``` javascript
TASK_BLANK
TASK_SELF
TASK_RESOURCE
```

ex:

``` lua
taskDef = {
  -- !! static recursion !!
  x = def:run(def.TASK_SELF, ..), 
  -- require local resource
  y = def:require('registed_local_resource_name'),

  promised = function(self, taskResult)
    -- !! dynamic recursion !!
    self:run(taskResult.taskId, ..);
    -- try execute blank task
    self:execute_task(self.TASK_BLANK, {..})
  end
}
```

this is harpseal expanded interface.

## pedt.version

get support version of PEDT specifications, it's string value.

this is harpseal expanded interface.

# helpers

some tool/helpers include in the package.

## Harpseal.infra.taskhelper

``` lua
local Harpseal = require('harpseal');
local def = Harpseal.infra.taskhelper;
-- or
-- local def = require('harpseal.infra.taskhelper');

local taskDef = {
	x = def:run(...),
	y = def:map(...),
	...
}
```

a taskDef define helper. @see:

> $(harpseal)/testcase/t_loadTask.lua

## Harpseal.infra.httphelper

``` lua
local Harpseal = require('harpseal');
local httphelper = Harpseal.infra.httphelper;
-- or
-- local httphelper = require('harpseal.infra.httphelper');

local options = {
	...,
	distributed_request = httphelper.distributed_request
}

-- (...)
-- (in your business or main, call these)
httphelper.start()
```

a recommented/standard distributed request, and activate copas parallel loop with call .start() method in your code.

## Harpseal.tools.taskloader

``` lua
local Harpseal = require('harpseal');
local TaskLoader = Harpseal.tools.taskloader;
-- or
-- local TaskLoader = require('harpseal.tools.taskloader');

-- register center for debug only
--	*) you can copy dbg_register_center.lua to your project folder from $(harpseal)/infra/, or
--	*) require() it when luarocks installed, or
--	*) load 3rd register center.
local pedt = Harpseal:new({
	task_register_center = require('harpseal.dbg.register_center'), -- need luarocks
})
local loader = TaskLoader:new({ publisher = pedt })

-- load task by lua module name
--	*) with depth of the discover
local taskId = loader:loadByModule('testcase.tasks.t_task1')
..
```

a task loader tool, will load tasks by module name of taskDef file, with depth discovery for all members. @see:

> $(harpseal)/testcase/t_loadTask.lua

## pedt.lua utility

pedt.lua is a resource management utility. it's a command line tool:

``` bash
> lua pedt.lua
Usage:
	lua pedt.lua <action> [paraments]
	lua pedt.lua help
	lua pedt.lua
```

### action: help

it's default, ex:

``` 
> lua pedt.lua
```

Or,

``` lua
> lua pedt.lua help

> # force list center methods for default
> #   - the default task center is 'infra.dbg_register_center'
> lua pedt.lua help -l
Methods:
	- report

> # list center methods
> lua pedt.lua help -t tools.etcd
Methods:
	- show
	- list
```

### action: add

Add task into task_center, and show taskId. ex:

``` lua
> echo -n '{}' | lua pedt.lua add
task:99914b932bd37a50b983c5e7c90ae93b loaded from json.
```

the action usage:

``` center_module_name
lua pedt.lua add <task|-> [-t center_module_name] [-c context_type]
	paraments:
    	task:	optional, default is '-', include these types:
        	-			: char '-', task context from stdin
            modName		: lua module name, task context from loaded module
            fileName	: filename, will call loadfile(fileName)
            context		: context, will load target module, run and return taskDef
		-t center_module_name
        	default is 'infra.dbg_register_center'
		-c context_type
        	context types, value include 'module/file/scrip/json'
```

ex:

``` bash
# add from script string
> lua pedt.lua add 'return {x=100}' -c 'script'
task:898bd5b2c59929cbac99aadc42ce1054 loaded from script.

# add context from json
> cat infra/samples/taskDef.json | lua pedt.lua add -c 'json'
task:68bb82e2a6bcbb5f9a83b93c85cff07a loaded from json.

# add form file
> echo -n 'return {}' > t.lua
> lua pedt.lua add ./t.lua -c 'file'
task:d751713988987e9331980363e24189ce loaded from file: ./t.lua

> # add from module name
> lua pedt.lua add t -c 'module'
task:d751713988987e9331980363e24189ce loaded from module: t
```

you can set a task_center with the center_module_name parament, ex:

``` bash
> echo -n '{}' | lua pedt.lua add -t 'tools.etcd'
```

the 'tools.etcd' module name point to './tools/etcd.lua' file. you midify

> var etcdServer = { url = '...

 to config it.

### action: run

Run a task. ex:

``` bash
# run it
> echo -n '{}' | lua pedt.lua run -a 'a=1&b=2'
```

the action usage:

``` 
lua pedt.lua add <task|-> [-t center_module_name] [-c context_type] [-a args]
	paraments:
    	task:	optional, default is '-', @see action:add
		-t center_module_name, @see action:add
		-c context_type, @see action:add, force set 'task' when <task> is taskId
        -a args, url query string or json text
```

Example 1, with default memory based task center:

``` bash
# run script from stdin
> echo -n '{}' | lua pedt.lua run -a 'a=1&b=2'
{
  "a": "1",
  "b": "2"
}

# with json arguments
> echo -n '{}' | lua pedt.lua run -a '{"x":1, "y":false}'
{
  "x": 1,
  "y": false
}

# execute task from script, and with arguments
> lua pedt.lua run -c 'script' -a '{"message": "Hello World!"}'\
	'return {promised=function(_, r) print(r.message); return true end}'
Hello World!
true
```

Example 2, with specific task center:

``` bash
# add a task into task center
> echo -n '{}' | lua pedt.lua add -t tools.etcd
task:99914b932bd37a50b983c5e7c90ae93b loaded from json.

# and, run the task from specific task center
> lua pedt.lua run 'task:99914b932bd37a50b983c5e7c90ae93b' -a '{"x":1, "y":false}' -t tools.etcd
{
  "x": 1,
  "y": false
}
```

### action: methods

execute a task center specific method. ex:

``` bash
> lua pedt.lua report
=============================================
OUTPUT dbg_storage
=============================================
```

Usage:

``` 
lua pedt.lua <method> [task] [-a args]
	paraments:
    	task:	optional, default is none
        -a args, url query string or json text
```

ex:

``` bash
# first, list methods for task center
> lua pedt.lua help -t tools.etcd
Methods:
	 - show
	 - list

# next, run 'list' method as action
> lua pedt.lua list -t tools.etcd
1	/N4C/task_center/tasks/99914b932bd37a50b983c5e7c90ae93b
2	/N4C/task_center/tasks/d751713988987e9331980363e24189ce
3	/N4C/task_center/tasks/778e25e48daf7a9ab49d00909afbdaa4

# and, show a task
> lua pedt.lua show '778e25e48daf7a9ab49d00909afbdaa4' -t 'tools.etcd'
{
  "info": {
    "arguments": {
      "p1": "new value"
    },
    "run": "script:javascript:base64:ZnVuY3Rpb24gb..."
  },
  "p1": "default value"
}
```

# testcase

try these:

``` bash
> # launch redpoll as service, require NodeJS
> # (for test only)
> git clone https://github.com/aimingoo/redpoll
> node redpoll/testcase/t_executor.js

> # start new shell and continue
> luarocks install luasocket
> luarocks install copas
> git clone 'https://github.com/aimingoo/harpseal'
> cd harpseal
> lua testcase/t_loadTask.lua
```

# history

``` text
2015.12.04	v1.0.4 released.
	- sync to redpoll v1.1.2, support default_rejected and logger.
    - add pedt.lua, a utility for task/resource center.
    - fix bug: extractTaskResult() cant process value type taskResult.
2015.11.08	v1.0.3 released.
	- minor changes for luarocks.
	- done.
2015.11.08	v1.0.2 released.
	- minor changes and rockspec updated again.
	- a register center published at harpseal.dbg.register_center.
2015.11.08	v1.0.1 released.
	- minor changes and rockspec updated.
2016.11.08	v1.0.0 released.
```