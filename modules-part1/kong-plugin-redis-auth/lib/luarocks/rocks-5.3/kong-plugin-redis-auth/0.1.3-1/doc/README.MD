# Kong-plugin-redis-auth

Just like kong plugin `key-auth`, storage key in external redis, valid key, return json.

## Install

```bash

luarocks install kong-plugin-redis-auth

```

## Setting

```

_format_version: "1.1"

plugins:
- name: redis-auth
  config: 
    hide_credentials: true
    redis_host: redis
    redis_port: 6379
    redis_key_prefix: 'redis-auth:'
    consumer_keys:
      - id
      - empnum
    anonymous: true
    anonymous_consumer: '{ "id": 10000, "type": "person", "name": "anonymous" }'
    anonymous_paths:
      - /public

services:
- name: public-service
  url: http://localhost:5000/
  routes:
  - name: public-route
    paths:
    - /public

- name: private-service
  url: https://cn.bing.com
  routes:
  - name: private-route
    paths:
    - /private/


```

