# Oauth2-ACL plugin for kong

It allows to use oauth2 scopes to restrict acces to routes or services in kong. 
Use it in conjuntion with official oauth2 plugin.

It's based on oficials Kong's ACL plugin.

## Install

### From luarocks server

Just run

```
luarocks install oauth2-acl
```

### From source code

You can also put source code on Kong host, change to directory and run.

```
luarocks make
```

## Example setup kong for a service

```
curl -X POST {KONG_HOST}/services/{SERVICE_NAME}/plugins \
    --data "name=oauth2-acl" \
    --data "config.blacklist=address"
```

## Example setup kong for a route

```
curl -X POST {KONG_HOST}/routes/{ROUTE_NAME}/plugins \
    --data "name=oauth2-acl" \
    --data "config.whitelist=email phone"
```