# RPC-prizm 
[![Build Status](https://travis-ci.org/ridnlee/rpc-prizm.svg?branch=master)](https://travis-ci.org/ridnlee/rpc-prizm)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/ridnlee/rpc-prizm/master/LICENSE)

RPC-prizm is transparent for clients JSON-RPC gateway based on Nginx+Lua. 

It parses, rebuilds (in case _batch_) and routes rpc requests between several services and aggregates reponses (in case _batch_).
## Installation
For using rpc-prizm you have to have nginx compiled with
[ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module#installation) module.
Take a look at the `example/provision.sh` file to get a tip on how to do it.

RPC-prizm can be installed via the [luarocks](https://luarocks.org/modules/ridnlee/rpc-prizm) package manager.
Just run:
```bash
luarocks install rpc-prizm
```
## Usage
Nginx server config
```nginx
    location / {
        default_type 'application/json';
        access_by_lua_file /etc/nginx/prizm/main.lua;
    }
    
    location /serv1 {
        proxy_pass       'http://service1';
    }

    location /serv2 {
        proxy_pass       'http://service2';
    }

    location /default {
        proxy_pass       'http://default';
    }
```
main.lua
```lua
local Prizm = require "rpc-prizm" --main module
local Router = require "rpc-prizm.router" --router module, manage routing 
local Logger = require "rpc-prizm.logger"  --logger module, write log
local ResponseBuilder = require "rpc-prizm.response_builder" -- response module, build response 
local Proxy = require "rpc-prizm.proxy" -- reverse proxy module, manage requests to services and aggregate responses
local Json = require "cjson" -- json encode|decode library

--List of routs, request method is used for determine proper rule, regular expressions is used  
local router = Router:new({
    {rule='v1%.([^%.]+).*', addr='/serv1'},
    {rule='v2%.([^%.]+).*', addr='/serv2'},
    {rule='.*', addr='/default'}, --used if no rule matches
})

local logger = Logger:new(ngx, true)

local proxy = Proxy:new(ngx, logger)

local response_builder = ResponseBuilder:new(Json)

local rpcprizm = Prizm:init({
    json = Json,
    ngx = ngx,
    router = router,
    logger = logger,
    proxy = proxy,
    response_builder = response_builder,
    hooks = {
        pre = function (prizm) end, --is evaluated before all requests are processed;
        post = function (prizm) end, --is evaluated after all requests are processed;
        pre_request = function (request, prizm) end --is evaluated before every request is processed, set return value to response if returns string;
    },
})

-- Send multi requst and get multi response
rpcprizm:run()
rpcprizm:print_responses()

```

## Running the example
Test code also contains an example of JWT validation.
  
Build the docker image
```
docker build -t prizm .
```
Run container instance
```
docker run -p 8881:8881 --name prizm_test prizm
```
Send POST request to apigate hosts on http://localhost:8181
```curl
curl -X POST \
  http://localhost:8881/ \
  -H 'Content-Type: application/json' \
  -d '[
	{
    "jsonrpc": "2.0",
    "method": "v2.method",
    "params": {
        "param1":1,
        "param2":2
    },
    "id": 2
},
{
    "jsonrpc": "2.0",
    "method": "v4.method",
    "params": {
        "param1":1,
        "param2":2
    },
    "id": 3
}
]'
```

Particular docker file for running tests
```
 docker build -f Dockerfile-test -t prizm-test .
 
```




Based on [Lugate](https://github.com/zinovyev/lugate)