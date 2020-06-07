# Kong User Agent Based Routing

## Overview
This plugin will change upstream service based on presence of config header to config destination service.

```bash
$ curl -X POST http://kong:8001/services/{service}/plugins \
    --data "name=kong-user-agent-based-routing" \
    --data "config.user_agent_header: is_mweb" \
    --data "config.destination: portal-mweb"
```

| Parameter  | Description |
| ------------- | ------------- |
| `config.user_agent_header`  | Header to look for in order to route.  |
| `config.destination` | Name of service to route to if header is present.   |


## Installation
Recommended:
```
$ luarocks install kong-user-agent-based-routing
```

Optional
```
$ git clone https://github.com/bogas04/kong-user-agent-based-routing
$ cd /path/to/kong/plugins/kong-user-agent-based-routing
$ luarocks make *.rockspec
```
