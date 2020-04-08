# Name

lua-resty-upstream-healthcheck.的一点点定制

[toc]



# Status

This library is still under early development but is already production ready.

# Synopsis

```nginx
http {
    lua_package_path "/path/to/lua-resty-upstream-healthcheck/lib/?.lua;;";

    # sample upstream block:
    upstream foo.com {
        server 127.0.0.1:12354;
        server 127.0.0.1:12355;
        server 127.0.0.1:12356 backup;
    }

    # the size depends on the number of servers in upstream {}:
    lua_shared_dict healthcheck 1m;

    lua_socket_log_errors off;

    init_worker_by_lua_block {
        local hc = require "resty.uh"

        local ok, err = hc.checker{
            exclude_lists = {"a.b.com","b.c.com",}, -- 排除清单，不会进行检查
            type = "http",
            http_req = "GET /status HTTP/1.0\r\nHost: foo.com\r\n\r\n",
                    -- raw HTTP request for checking
            interval = 2000,  -- run the check cycle every 2 sec
            timeout = 1000,   -- 1 sec is the timeout for network operations
            fall = 3,  -- # of successive failures before turning a peer down
            rise = 2,  -- # of successive successes before turning a peer up
            valid_statuses = {200, 302},  -- a list valid HTTP status code
            concurrency = 10,  -- concurrency level for test requests
            ha_interval = 20， -- ha模式检查周期，单位秒
        }
        if not ok then
            ngx.log(ngx.ERR, "failed to spawn health checker: ", err)
            return
        end


    }
    
    #查看状态
    
    server {
            listen       8088;
            server_name  localhost;
            default_type application/json;
            # status page for all the peers:
            location = /status {
                access_log off;

                default_type text/plain;
                content_by_lua_block {
                    local hc = require "resty.uh"
                    ngx.say("Nginx Worker PID: ", ngx.worker.pid())
                    ngx.print(hc.status_page())
                }
            }
        #json 返回接口
            location = /records {
                access_log off;
                content_by_lua_block {
                    local hc = require("resty.uh")
                    return ngx.say(hc.status())
                }
            }
        }


}
```

# Install

`luarocks install lua-resty-uh` 

# Version Feature
## 0.05

- 修改`exclude_lists`列表通过shared.dict实现

- 原`status()`函数变更用途，作为API主入口存在。在不包含参数请求的场景下，实现与0.0.4版本保持一致

- 增加了管理`exclude_lists`排除列表记录的接口，提供添加、删除、查询功能。

  **注意**：由于`exclude_lists`列表从本版本后通过shared.dict实现，所以通过接口添加的记录，会在缓存失效(如Nginx master进程更换后)丢失记录。如果需要持久化的保持记录，还是应该通过检查函数参数中添加。
  
- 添加了可以手动指定特定upstream下的节点下线的功能，设计目的主要是为了发布时提供简单的后端灰度能力(可以手动的屏蔽部分节点)，该功能必须通过接口来操作。

- 提供了`exclude_lists`和`peer_manual_down`的增删查接口

  

## 0.0.4

- 删除了*opts.shm*参数.模块绑定使用`lua_shared_dict = "healthcheck"`
- 删除了原module参数`upstream_checker_statuses`，该参数会导致多worker及interval设置数量较大时，多个worker进程数据不同步，从而通过`status_page`函数获取到错误的数据
- `update_upstream_checker_status`函数修改通过SHM实现多进程状态的同步
- 添加新的json格式返回函数`_M.status()`,主要用于接口调用，该函数可以更丰富的返回节点状态信息
- 添加可选参数`opts.ha_interval`，用于在HA部署模式下，通过检查本地`eth0`、`bond0`、`em0`接口ipv4地址数量，排除备机向upstream发起检查的简单过滤。该功能仅在`CentOS6.x`， `CentOS7.x`下测试可用
- 伴随 `opts.ha_interval`参数的添加，函数`_M.status()`，`status_page()`，会根据参数的添加返回额外的信息。

## 0.0.2

- 默认检查所有upstream *version 0.0.2*




# Methods

## checker

**syntax:** `ok, err = healthcheck.checker(options)`

**context:** *init_worker_by_lua*

Healthchecker for all the upstreams,exlude the record in the "exclude_lists".

Remove the the spawn_checker‘s option "upstream",Add new option "exclude_lists",if not exclude_lists given then all the upstreams will check.

默认检查所有的upstream后端，除非给定的options参数中，包含`exclude_lists`排除列表

注意：

- 原 `spawn_checker()`函数参数*options.upstream*不在生效，该参数无需给予。(即便给了，也不会生效)

- `exclude_lists`参数类型必须为*array-table*，每个在列表中的值都**不会**加入检查目标

  例:

  ```
  exclude_lists = {"a.b.com","b.c.com",}, 
  ```

- 核心实现为原模块的`spawn_checker()`，每个upstream会调用一次，所以可能会有多次返回

**opts：**

- type：检查协议，目前只支持**http**
- http_req：http请求原始信息
- interval：每一个upstream检查的间隔时间
- timeout：检查网络超时时间
- fall：失败次数，检查失败大于该失败次数后，节点下线
- rise：成功次数，检查成功大于成功次数后，节点上线
- valid_statuses ：节点健康的http 响应码列表
- concurrency：同一个upstream组中，同时并发检查后端的轻线程数

*new opts:*

- exclude_lists：(optional)。 *version 0.0.2* 

  显示申明的一个列表，指明不检查指定后端upstream名称。 它是一个`array-table`类型的值。

- ha_interval: (optional)。 *version 0.0.4* 

  - 用于在HA部署模式下，使备用Nginx不发起向后端的检查，以降低节点检查的总请求量。

  - 它的输入类型是一个**数字**，单位：**秒**,最小值：**10**，用于声明是否需要HA部署模式下的主/备状态检查得定时器的**时间间隔**。

  - 检查的本质是通过检查`eth0`或`bond0`接口下，`ipv4` `inet`条目数实现的。默认场景下`eth0`或`bond0`接口下`inet`条目数大于**1**条时，认为该节点是主节点。

  - 如果该参数提供，则`status_page`函数会同时提供如：`HA Mode: Slaver`的提示。如果节点处于`slaver`模式，因为不向后端发起检查，所以不会返回后端节点信息。
  
  - 会根据节点模式，主动关闭/开启后端检查请求。
  
    
  
  虽然该实现上不足之处明显，不过总的来说，大多数场景下并不会造成更坏的情况。**除非你的网络不在`eth0`或`bond0`接口下提供服务的情况下，同时启用了该配置，那么健康度检查功能将会失效。**
  
  





## status_page

**syntax:** `str, err = hc.status_page()`

**context:** *any*

一个简单的返回节点状态的字符的函数

One typical output is

```
Upstream foo.com
    Primary Peers
        127.0.0.1:12354 up
        127.0.0.1:12355 DOWN
    Backup Peers
        127.0.0.1:12356 up

Upstream bar.com
    Primary Peers
        127.0.0.1:12354 up
        127.0.0.1:12355 DOWN
        127.0.0.1:12357 DOWN
    Backup Peers
        127.0.0.1:12356 up
```

If an upstream has no health checkers, then it will be marked by `(NO checkers)`, as in

```
Upstream foo.com (NO checkers)
    Primary Peers
        127.0.0.1:12354 up
        127.0.0.1:12355 up
    Backup Peers
        127.0.0.1:12356 up
```

If you indeed have spawned a healthchecker in `init_worker_by_lua*`, then you should really
check out the NGINX error log file to see if there is any fatal errors aborting the healthchecker threads.



若启用ha_interval参数：

Slaver节点

```
HA Mode: Slaver
```

Master节点

```
HA Mode: Master
Upstream foo
    Primary Peers
        127.0.0.1:12354 DOWN
        127.0.0.1:12355 DOWN
    Backup Peers
        127.0.0.1:12356 DOWN
```



## status

**syntax:** `json, err = hc.status()`

**context:** *any*

接口主函数。目前仅接受`GET`请求，参数通过uri拼接完成(为了便于一线同学可以通过浏览器简单操作)。

接口提供主要提供：

### all_status

不带任何参数请求，返回节点详细状态的的函数。返回字符格式为JSON。

典型的返回如下：

```json
{
  "err_msg": "",
  "msg": {
    "upstreams": [
      {
        "backup": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:93",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ],
        "name": "lintest",
        "checked": true,
        "primary": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:91",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          },
          {
            "current_weight": 0,
            "id": 1,
            "name": "192.168.1.180:92",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ]
      },
      {
        "backup": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:93",
            "conns": 0,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ],
        "name": "lintest2",
        "checked": false,
        "primary": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:94",
            "conns": 0,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ]
      },
      {
        "backup": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:93",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ],
        "name": "lintest3",
        "checked": true,
        "primary": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:94",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ]
      },
      {
        "backup": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:93",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ],
        "name": "lintest4",
        "checked": true,
        "primary": [
          {
            "current_weight": 0,
            "id": 0,
            "name": "192.168.1.180:94",
            "conns": 0,
            "down": true,
            "weight": 1,
            "fail_timeout": 10,
            "effective_weight": 1,
            "fails": 0,
            "max_fails": 1
          }
        ]
      }
    ],
    "ha_mode": "Master"
  },
  "status": "ok"
}

```



输出层级结构为：

```
{
    "err_msg": "",
    "msg": {},
    "status": "ok"
}
```



- status 请求执行状态，可能的返回结果有 `ok`或 `err`

- err_msg 请求错误信息，当`status`返回为`err`时，才会有输出对应的错误提示

- msg 主要消息体。消息内容有:

  - ha_mode HA状态。可能返回的值有`Disabled`,`Master`,`Slaver`

  - upstreams 节点状态的主要内容，这是一个复杂聚合的table,其主要结构为：

    ``"upstreams":[upstream1,upstream2,...]`

    一个upstream下的结构为：

    - name: upstream的名称
    - checked：是否进行健康度检查
    - backup：备节点数据
    - primary：主节点数据

    ```json
    "upstreams": [
        {
          "backup": [
            {
              "current_weight": 0,
              "id": 0,
              "name": "ip:93",
              "conns": 0,
              "down": true,
              "weight": 1,
              "fail_timeout": 10,
              "effective_weight": 1,
              "fails": 0,
              "max_fails": 1
            }
          ],
          "name": "upstream_name",
          "checked": true,
          "primary": [
            {
              "current_weight": 0,
              "id": 0,
              "name": "ip:91",
              "conns": 0,
              "down": true,
              "weight": 1,
              "fail_timeout": 10,
              "effective_weight": 1,
              "fails": 0,
              "max_fails": 1
            },
            {
              "current_weight": 0,
              "id": 1,
              "name": "ip:92",
              "conns": 0,
              "down": true,
              "weight": 1,
              "fail_timeout": 10,
              "effective_weight": 1,
              "fails": 0,
              "max_fails": 1
            }
          ]
        }
      ]
    ```

关于节点信息的参数：

- current_weight

- effective_weight

- fail_timeout

- fails

- id

  Identifier (ID) for the peer. This ID can be used to reference a peer in a group in the peer modifying API.

- max_fails

- name

  Socket address for the current peer

- weight

- accessed

  Timestamp for the last access (in seconds since the Epoch)

- checked

  Timestamp for the last check (in seconds since the Epoch)

- down

  Holds true if the peer has been marked as "down", otherwise this key is not present

- conns

  Number of active connections to the peer (this requires NGINX 1.9.0 or above).



# API定义

## exclude_lists

操作不检查清单的的upstream(checker)。

**注意**：

- 非通过`opts`参数添加的upstream，因记录保存在缓存中，在Nginx master进程crash后，记录会消失，普通的HUP(`nginx -s reload`)则不受影响。
- 注意通过接口提交的记录会立即被接受，但是只会在下一轮health_checker定时器启动时生效执行，如果你的`interval`值设置的非常大，那么结果可能不会如预期一样执行。



**method**：GET

**args**: 

| key  | 参数                                      | 类型   | 必须  | 描述                                                         |
| ---- | ----------------------------------------- | ------ | ----- | ------------------------------------------------------------ |
| t    | `ex`                                      | string | true  | 接口请求的对象，exclude_lists                                |
| u    | upstream名称                              | string | true  | upstream名称需要和`nginx.conf`中的名称保持一致               |
| a    | `set`：添加<br>`del`: 删除 <br>`get`:查询 | string | true  | 请求的动作，仅支持参数列表中的三种动作                       |
| ttl  | 失效时间                                  | number | false | 仅在`a=set`，添加新记录时，可以增加额外的可选参数ttl，用于描述该条策略的失效时间，失效时间单位为**秒**，到时间后，该记录会从缓存中自动删除。如果不添加该参数，则默认为**0**，该记录不失效 |

**example**：

**set**

```http
http://host/endpoint?t=ex&u=upstream_name&a=set&ttl=30
```

**del**

```http
http://host/endpoint?t=ex&u=upstream_name&a=del
```

**get**

```http
http://host/endpoint?t=ex&u=upstream_name&a=get
```





## peer_manual_down

操作特定节点手动down(不论后端是否实际down)

**注意**：因记录保存在缓存中，在Nginx master进程crash后，记录会消失，普通的HUP(`nginx -s reload`)则不受影响。当指定的`ttl`超时时间过期过，缓存中该记录将会过期(失效)。

**method**：GET

**args**: 



| key  | 参数                                      | 类型   | 必须 | 描述                                                         |
| ---- | ----------------------------------------- | ------ | ---- | ------------------------------------------------------------ |
| t    | `gray`                                    | string | true | 接口请求的对象，peer_manual_down                             |
| u    | upstream名称                              | string | true | upstream名称需要和`nginx.conf`中的名称保持一致               |
| p    | upstream中的后端节点                      | string | true | 常见的记录为`IP:PORT`或`域名`格式。注意名称必须与`nginx.conf`中配置的内容**完全一致**。 |
| a    | `set`：添加<br>`del`: 删除 <br>`get`:查询 | string | true | 请求的动作，仅支持参数列表中的三种动作                       |
| ttl  | 失效时间                                  | number | true | 仅在`a=set`，添加新记录时，可以增加额外的可选参数ttl，用于描述该条策略的失效时间，失效时间单位为**秒**，到时间后，该记录会从缓存中自动删除。如果不添加该参数，则默认为**0**，该记录不失效 |



**example**:

**set**

```http
http://host/endpoint?t=gray&u=upstream_name&a=set&p=peer_ip:peer_port&ttl=60
```

```json
{"err_msg":"","msg":"Set into shm succeded","status":"ok"}
```



**del**

```http
http://host/endpoint?t=gray&u=upstream_name&a=del&p=peer_ip:peer_port
```

```json
{"err_msg":"","msg":"Delete succeded","status":"ok"}
```



**get**

```http
http://host/endpoint?t=gray&u=upstream_name&a=get&p=peer_ip:peer_port
```

```json
{"err_msg":"","msg":"found","status":"ok"}
```



# 作用逻辑

