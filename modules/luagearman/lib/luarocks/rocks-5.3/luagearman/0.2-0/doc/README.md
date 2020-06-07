# luagearman


[Gearman](http://gearman.org/)をLuajit FFIで呼び出すモジュールです。

# 依存

Luajit >= 2.1

gearmand >= 1.1.18

# インストール
`$ luarocks install luagearman`

# 使い方

client

```lua
--[[
	gearman client
]]
local gearman = require "luagearman.gearman"
local client = require "luagearman.client"
local argment = require "luagearman.argment"

local _client = client.init()
_client:create(nil)
local ret = _client:addServer("localhost", 0)

if gearman.failed(ret) then
	print("error => ", _client:error())
	os.exit(1)
end

local _arg = argment.init()
_arg:make(nil, "Reverse Me")

local result, size, value = _client:excute("reverse", nil, nil, _arg, nil)
if result == nil then
	print("error => ", _client:error())
	os.exit(1)
end

print("result ", result)
print("value ", value)
print("size ", size)

_client:free()
```

worker

```lua
--[[
	gearman worker
]]
local gearman = require "luagearman.gearman"
local worker = require "luagearman.worker"

local _worker = worker.init()
_worker:create()

if gearman.failed(_worker:addServer("localhost", 0)) then
	print("error => ", _worker:error())
	os.exit(1)
end

local worker_function = function(workload)
	print("worker!!")
	print("workload => ", workload)

	return string.reverse(workload)
end

if gearman.failed(_worker:addFunction("reverse", 10, worker_function, nil)) then
	print(_worker:error())
	os.exit(1)
end

while true do
	local ret = _worker:work()
	if gearman.failed(ret) then
		print(_worker:error())
		break
	end
end

_worker:free()
```

# API

## class client

* Gearmanのクライアント機能を提供する。


### .init

インスタンス化

### :create

クライアントを初期化する。

gearman_client_createの機能に相当する。

* 引数 : client


### :addServer

サーバーを追加する。

gearman_client_add_serverの機能に相当する。

* 引数 : host
* 引数 : port

### :free

インスタンスを開放する。

gearman_client_freeの機能に相当する。

### :excute

ワーカーの関数を呼び出す。

gearman_executeの機能に相当する。

* 引数 : function_name
* 引数 : unique
* 引数 : workload
* 引数 : arguments
* 引数 : context

### :error

最新のエラーを文字列として取得する。

gearman_client_errorの機能に相当する。

### :errorCode

最新のエラーをcodeとして取得する。

gearman_client_error_codeの機能に相当する。

### :errno

最新のエラーをnoとして取得する。

gearman_client_errnoの機能に相当する。

### :options

optionsを取得する。

gearman_client_optionsの機能に相当する。

### :setOptions

optionsを設定する。

gearman_client_set_optionsの機能に相当する。

* 引数 : options

### :timeout

timeoutを取得する。

gearman_client_timeoutの機能に相当する。

### :setTimeout

timeoutを設定する。

gearman_client_set_timeoutの機能に相当する。

* 引数 : timeout


## class worker

* Gearmanのワーカー機能を提供する。

### .init

インスタンス化。

### :create

クライアントを初期化する。

gearman_worker_createの機能に相当する。

* 引数 : client

### :addServer

サーバーを追加する。

gearman_worker_add_serverの機能に相当する。

* 引数 : host
* 引数 : port

### :free

インスタンスを開放する。

gearman_worker_freeの機能に相当する。

### :addFunction

ワーカー関数を追加する。

gearman_worker_add_functionの機能に相当する。

* 引数 : function_name
* 引数 : timeout
* 引数 : func
* 引数 : context

### :error

最新のエラーを文字列として取得する。

gearman_worker_errorの機能に相当する。

### :work

クライアントからの接続を待機する。

gearman_worker_workの機能に相当する。

### :errno

最新のエラーをnoとして取得する。

gearman_worker_errnoの機能に相当する。

### :options

optionsを取得する。

gearman_worker_optionsの機能に相当する。

### :setOptions

optionsを設定する。

gearman_worker_set_optionsの機能に相当する。

* 引数 : options

### :timeout

timeoutを取得する。

gearman_worker_timeoutの機能に相当する。

### :setTimeout

timeoutを設定する。

gearman_worker_set_timeoutの機能に相当する。

* 引数 : timeout


## class argument

* client:excuteに渡すargumentsインスタンスを保持する。

### .init

インスタンス化。

### :make

値をセットする。

* 引数 : name
* 引数 : value

## class gearman

### .failed

戻り値がgearman_return_tの関数において結果が失敗であればtrueを返す。

* 引数 : rc

### .success

戻り値がgearman_return_tの関数において結果が成功であればtrueを返す。

* 引数 : rc
