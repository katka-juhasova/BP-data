# Kong-plugin-redis-auth

Just like kong plugin `key-auth`, storage key in external redis, valid key, return json.

## Install

```bash

luarocks install kong-plugin-redis-auth

```

## Setting

```

plugins:
- name: redis-auth
  config: 
  	key-names: apikey
    hide_credentials: true
    redis_host: redis_host
    redis_port: 6379
    redis_key_prefix: 'redis-auth:'
    consumer_keys:
      - id
      - username

```

