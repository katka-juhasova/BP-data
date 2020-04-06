# kong-forwarded-user-auth

Access Control with `X-Forwarded-User` header.

It is recommended to use with [oauth2_proxy](https://github.com/pusher/oauth2_proxy).

## Install

```
# luarocks make
```

## Enable

```
# export KONG_PLUGINS=bundled,forwarded-user-auth
# kong start -vv
```
