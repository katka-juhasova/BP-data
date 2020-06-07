Kong File Log Exclusion
=====================================
Built on top of Kong's built-in file logging plugin
(https://getkong.org/plugins/file-log/).  It supports the same configuration
and outputs the same format as the built-in plugin but provides additional configuration
for excluding attributes attributes in the output.

Installation
------------
Installing with luarocks:
```
$ luarocks install kong-file-log-exclusion
```

Configuration
-------------
Configuration is similar to Kong's default file logging plugin
(https://getkong.org/plugins/file-log/). Excluded attributes can be specified
using the `exclusion` config.
```
curl -X POST http://kong:8001/apis/{api}/plugins \
       --data "name=file-log-exclusion" \
       --data "config.path=/tmp/file.log" \
       --data "config.exclusion=request.headers, response"
```
`exclusion` is optional and expects an array containing the attributes to be
excluded in the log.

Sample Log
----------
Without the exclusion configuration, default log looks like:
```
{
  "request": {
    "method": "GET",
      "uri": "/get",
      "size": "75",
      "request_uri": "http://httpbin.org:8000/get",
      "querystring": {},
      "headers": {
        "accept": "*/*",
        "host": "httpbin.org",
        "user-agent": "curl/7.37.1"
      }
  },
  "response": {
    "status": 200,
    "size": "434",
    "headers": {
      "Content-Length": "197",
      "via": "kong/0.3.0",
      "Connection": "close",
      "access-control-allow-credentials": "true",
      "Content-Type": "application/json",
      "server": "nginx",
      "access-control-allow-origin": "*"
    }
  },
  "authenticated_entity": {
    "consumer_id": "80f74eef-31b8-45d5-c525-ae532297ea8e",
    "created_at":   1437643103000,
    "id": "eaa330c0-4cff-47f5-c79e-b2e4f355207e",
    "key": "2b64e2f0193851d4135a2e885cd08a65"
  },
  "api": {
    "request_host": "test.com",
    "upstream_url": "http://mockbin.org/",
    "created_at": 1432855823000,
    "name": "test.com",
    "id": "fbaf95a1-cd04-4bf6-cb73-6cb3285fef58"
  },
  "latencies": {
    "proxy": 1430,
    "kong": 9,
    "request": 1921
  },
  "started_at": 1433209822425,
  "client_ip": "127.0.0.1"
}
```

With `config.exclusion=request.headers, response`:
```
{
  "request": {
    "method": "GET",
      "uri": "/get",
      "size": "75",
      "request_uri": "http://httpbin.org:8000/get",
      "querystring": {}
  },
  "authenticated_entity": {
    "consumer_id": "80f74eef-31b8-45d5-c525-ae532297ea8e",
    "created_at":   1437643103000,
    "id": "eaa330c0-4cff-47f5-c79e-b2e4f355207e",
    "key": "2b64e2f0193851d4135a2e885cd08a65"
  },
  "api": {
    "request_host": "test.com",
    "upstream_url": "http://mockbin.org/",
    "created_at": 1432855823000,
    "name": "test.com",
    "id": "fbaf95a1-cd04-4bf6-cb73-6cb3285fef58"
  },
  "latencies": {
    "proxy": 1430,
    "kong": 9,
    "request": 1921
  },
  "started_at": 1433209822425,
  "client_ip": "127.0.0.1"
}
```

