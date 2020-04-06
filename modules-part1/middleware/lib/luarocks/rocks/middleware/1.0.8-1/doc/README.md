# Kong Middleware 

A Kong plugin that enables services to act as middlewares for requests.

# Introducation 

> In some cases, you may need to protect your services in `plugin` layer using custom logic.
> You can do it with `custom plugin`. But, you must to write it using lua and install it using luarocks.
> When your plugin updated, you must to re-install it.
> So, this plugin try to resolve these problems.

# Installation

## luarocks

```bash
$ luarocks install middleware
```

## Load the plugin

- environment

```bash
export KONG_CUSTOM_PLUGINS=middleware
```

`----OR-----`

- configuration file

```yaml
custom_plugins:
  - middleware
```

# Enabling plugin for your api

```bash
$ curl -i -X POST \
  --url http://localhost:8001/apis/example-api/plugins/ \
  --data 'name=middleware'
  --data 'config.url=http://your-middleware-service/foo'
```

|params|required|default|description|
|---|---|---|---|
|name|true||The name of the plugin to use, in this case: `middleware`|
|config.method|false||method to call the middleware service url, default to the upstream method|
|config.url|true||The middleware service url|
|config.headers|fasle|`{}`|The headers will send to `config.url`, some things like `apikey`|

# How to write your middleware

- It will receive headers that include the `config.headers` and `X-Target-Method`, `X-Target-Scheme`, `X-Target-Host`, `X-Target-Port`, `X-Target-Path` and `X-Target-Uri`
- It can response http status code great than 299 to stop the original api proxy, and the response(`status`, `body`, `headers`) to your request.
- It can response `custom headers`(`X-*`) upstream to your original api.

